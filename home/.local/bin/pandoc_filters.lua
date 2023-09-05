function Link (elem)
    elem.target = elem.target:gsub('%.md$', '.html')

    if elem.title == nil then
        elem.title = elem.content
    end

    if string.match(elem.target, '^https?://') then
        elem.attributes.target = '_blank'
    end

    return elem
end

function Header (elem)
    elem.level = elem.level + 1

    return elem
end

function Meta (m)
    if m['date-meta'] == nil then
        m['date-meta'] = os.date("%B %e, %Y")
    end

    if m['author-meta'] == nil then
        m['author-meta'] = 'Matheus Sampaio <matheus@sampaio.us>'
    end

    return m
end


function lf (o)
    for key, value in pairs(o) do
        print(key, value)
    end
end
