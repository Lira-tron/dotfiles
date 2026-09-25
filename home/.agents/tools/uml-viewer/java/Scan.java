import com.sun.source.tree.*;
import com.sun.source.util.*;
import javax.lang.model.element.Modifier;
import javax.tools.*;
import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.stream.Collectors;

/** Syntax-only scanner: no project classes are loaded and no annotation processors run. */
public final class Scan {
    private final Path root;
    private final List<Map<String,Object>> nodes = new ArrayList<>();
    private final List<Map<String,Object>> edges = new ArrayList<>();
    private final List<String> warnings = new ArrayList<>();
    private final Set<String> packages = new HashSet<>();
    private final Map<String,List<String>> types = new HashMap<>();
    private final List<Relation> relations = new ArrayList<>();
    private SourcePositions positions;
    private record Relation(String from, String type, String kind, String pkg, Map<String,String> imports) {}

    private Scan(Path root) { this.root = root; }

    public static void main(String[] args) throws Exception {
        Scan scanner = new Scan(Path.of(args[0]));
        List<Path> files = new BufferedReader(new InputStreamReader(System.in))
            .lines().filter(s -> !s.isEmpty()).map(Path::of).toList();
        JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
        if (compiler == null) throw new IllegalStateException("A JDK 17+ is required");
        DiagnosticCollector<JavaFileObject> diagnostics = new DiagnosticCollector<>();
        try (StandardJavaFileManager manager = compiler.getStandardFileManager(diagnostics, null, null)) {
            JavacTask task = (JavacTask) compiler.getTask(null, manager, diagnostics,
                List.of("-proc:none"), null, manager.getJavaFileObjectsFromPaths(files));
            Iterable<? extends CompilationUnitTree> units = task.parse();
            scanner.positions = Trees.instance(task).getSourcePositions();
            for (CompilationUnitTree unit : units) scanner.scanUnit(unit);
        }
        for (Diagnostic<?> d : diagnostics.getDiagnostics()) {
            if (d.getKind() == Diagnostic.Kind.ERROR) throw new IllegalArgumentException(d.toString());
            scanner.warnings.add(d.toString());
        }
        scanner.resolveRelations();
        System.out.println(json(Map.of("nodes", scanner.nodes, "edges", scanner.edges, "warnings", scanner.warnings)));
    }

    private void scanUnit(CompilationUnitTree unit) {
        Path file = Path.of(unit.getSourceFile().toUri());
        String rel = root.relativize(file).toString().replace(File.separatorChar, '/');
        String pkg = unit.getPackageName() == null ? "(default)" : unit.getPackageName().toString();
        String pid = "java:" + pkg;
        if (packages.add(pid)) nodes.add(node(pid, pkg, "package", pkg, "", "", 0, 0, "", true));
        Map<String,String> imports = new HashMap<>();
        for (ImportTree im : unit.getImports()) {
            String full = im.getQualifiedIdentifier().toString();
            if (im.isStatic()) full = full.substring(0, full.lastIndexOf('.'));
            int dot = full.lastIndexOf('.');
            if (dot >= 0) {
                String target = full.substring(0, dot);
                edges.add(Map.of("from", pid, "to", "java:" + target, "kind", "imports"));
                if (!full.endsWith(".*")) imports.put(full.substring(dot + 1), full);
            }
        }
        new TreeScanner<Void,String>() {
            @Override public Void visitClass(ClassTree tree, String owner) {
                // Anonymous/local classes lack a stable architectural identity here.
                if (tree.getSimpleName().length() == 0) return null;
                String name = tree.getSimpleName().toString();
                String qualified = owner == null ? pkg + "." + name : owner + "." + name;
                String id = "java:" + rel + "#" + qualified;
                String parent = owner == null ? pid : "java:" + rel + "#" + owner;
                types.computeIfAbsent(qualified, k -> new ArrayList<>()).add(id);
                long start = line(unit, tree, false), end = line(unit, tree, true);
                nodes.add(node(id, name, tree.getKind().name().toLowerCase(Locale.ROOT), pkg, parent,
                    rel, start, end, qualified, tree.getModifiers().getFlags().contains(Modifier.PUBLIC)));
                if (tree.getExtendsClause() != null)
                    relations.add(new Relation(id, typeName(tree.getExtendsClause()), "extends", pkg, imports));
                for (Tree it : tree.getImplementsClause())
                    relations.add(new Relation(id, typeName(it), tree.getKind() == Tree.Kind.INTERFACE ? "extends" : "implements", pkg, imports));
                for (Tree member : tree.getMembers()) {
                    if (member instanceof ClassTree) scan(member, qualified);
                    else if (member instanceof MethodTree method) {
                        String methodName = method.getName().contentEquals("<init>") ? name : method.getName().toString();
                        String signature = methodName + "(" + method.getParameters().stream()
                            .map(p -> p.getType().toString()).collect(Collectors.joining(", ")) + ")";
                        if (method.getReturnType() != null) signature += " : " + method.getReturnType();
                        long ln = line(unit, method, false);
                        Map<String,Object> methodNode = node(id + "#" + methodName + ":" + ln, methodName,
                            method.getReturnType() == null ? "constructor" : "method", pkg, id, rel,
                            ln, line(unit, method, true), signature,
                            method.getModifiers().getFlags().contains(Modifier.PUBLIC) || tree.getKind() == Tree.Kind.INTERFACE);
                        methodNode.put("report_name", methodName);
                        String fileClass = file.getFileName().toString().replaceFirst("\\.java$", "");
                        methodNode.put("report_owner", pkg.equals("(default)") ? fileClass : pkg + "." + fileClass);
                        nodes.add(methodNode);
                    } else if (member instanceof VariableTree field) {
                        long ln = line(unit, field, false);
                        nodes.add(node(id + "#" + field.getName() + ":" + ln, field.getName().toString(), "field",
                            pkg, id, rel, ln, line(unit, field, true), field.getName() + " : " + field.getType(),
                            field.getModifiers().getFlags().contains(Modifier.PUBLIC)));
                    }
                }
                return null;
            }
        }.scan(unit, null);
    }

    private static String typeName(Tree t) {
        return t instanceof ParameterizedTypeTree p ? typeName(p.getType()) : t.toString();
    }

    private long line(CompilationUnitTree unit, Tree tree, boolean end) {
        long p = end ? positions.getEndPosition(unit, tree) - 1 : positions.getStartPosition(unit, tree);
        return p < 0 ? 1 : unit.getLineMap().getLineNumber(p);
    }

    private void resolveRelations() {
        for (Relation r : relations) {
            String full = r.imports.getOrDefault(r.type, r.pkg + "." + r.type);
            if (types.containsKey(r.type)) full = r.type;
            List<String> matches = types.getOrDefault(full, List.of());
            String target;
            if (matches.size() == 1) target = matches.get(0);
            else {
                target = "java:unresolved/" + r.type;
                warnings.add("Unresolved " + r.kind + " target " + r.type + " from " + r.from +
                    "; syntax analysis does not resolve wildcard imports or dependency classpaths.");
            }
            edges.add(Map.of("from", r.from, "to", target, "kind", r.kind));
        }
    }

    private static Map<String,Object> node(String id, String name, String kind, String pkg, String parent,
            String file, long line, long end, String signature, boolean visible) {
        Map<String,Object> n = new LinkedHashMap<>();
        n.put("id", id); n.put("name", name); n.put("kind", kind); n.put("lang", "java"); n.put("package", pkg);
        n.put("parent", parent); n.put("file", file); n.put("line", line); n.put("end_line", end);
        n.put("signature", signature); n.put("public", visible);
        return n;
    }

    private static String json(Object value) {
        if (value == null) return "null";
        if (value instanceof Number || value instanceof Boolean) return value.toString();
        if (value instanceof Map<?,?> m) return m.entrySet().stream()
            .map(e -> json(e.getKey().toString()) + ":" + json(e.getValue())).collect(Collectors.joining(",", "{", "}"));
        if (value instanceof Collection<?> c) return c.stream().map(Scan::json).collect(Collectors.joining(",", "[", "]"));
        StringBuilder b = new StringBuilder("\"");
        for (char ch : value.toString().toCharArray()) {
            switch (ch) {
                case '"' -> b.append("\\\"");
                case '\\' -> b.append("\\\\");
                case '\n' -> b.append("\\n");
                case '\r' -> b.append("\\r");
                case '\t' -> b.append("\\t");
                default -> { if (ch < 32) b.append(String.format("\\u%04x", (int) ch)); else b.append(ch); }
            }
        }
        return b.append('"').toString();
    }
}
