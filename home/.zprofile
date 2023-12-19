export TZ=/usr/share/zoneinfo/US/Pacific

if [ -f "$HOME/.zprofile.local" ]; then
    source "$HOME/.zprofile.local"
fi

