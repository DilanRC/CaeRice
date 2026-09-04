function fish_greeting
    if command -v fastfetch-pokemon &> /dev/null
        fastfetch-pokemon --key-padding-left 5
    else if command -v fastfetch &> /dev/null
        fastfetch --key-padding-left 5
    end
end
