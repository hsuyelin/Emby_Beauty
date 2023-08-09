# /bin/bash

customcss_plugin_path="$(pwd)/plugin/Emby.CustomCssJS.dll"
shooter_plugin_path="$(pwd)/plugin/Emby.MeiamSub.Shooter.dll"
thunder_plugin_path="$(pwd)/plugin/Emby.MeiamSub.Thunder.dll"
javScraper_plugin_path="$(pwd)/plugin/JavScraper.dll"
js_path="$(pwd)/res/CustomCssJS.js"

# emby beauty
emby_beautify() {
    # Get the container id/container name/container version of the current emby
    container_id=$(docker ps -a --filter "name=(?i)emby" --format '{{.ID}}' | head -n 1)
    container_name=$(docker inspect -f '{{.Name}}' "$container_id" 2>/dev/null | awk -F '/' '{print $2}')
    emby_version=$(docker inspect -f '{{.Config.Image}}' "$container_id" 2>/dev/null | awk -F ':' '{print $2}')

    if [[ -z "$container_id" || -z "$container_version" ]]; then
        echo "Emby container id or version is empty. Exiting..."
        echo "Please check that the container name contains the string emby (case insensitive)"
        exit 1
    fi

    echo "\nEmby container id: $container_id"
    echo "Emby container name: $container_name"
    echo "Emby container version: $emby_version"

    echo "\n------------- Emby beautify running ------------"
    # Copy customCssJS to the /config/plugins directory
    docker cp $customcss_plugin_path $container_id:config/plugins
    # Copy MeiamSubtitles shooter to the /config/plugins directory
    docker cp $shooter_plugin_path $container_id:config/plugins
    # Copy MeiamSubtitles thunder to the /config/plugins directory
    docker cp $thunder_plugin_path $container_id:config/plugins
    # Copy javScraper to the /config/plugins directory
    docker cp $javScraper_plugin_path $container_id:config/plugins

    # Copy Emby.CustomCssJS.dll to the /config/plugins directory
    emby_server_implementations_path="$(pwd)/plugin/$emby_version/Emby.Server.Implementations/Emby.Server.Implementations.dll"
    if [[ -f $emby_server_implementations_path ]]; then 
        # Backup original Emby.Server.Implementations.dll to Emby.Server.Implementations.dll.bak
        docker exec $container_id mv system/Emby.Server.Implementations.dll system/Emby.Server.Implementations.dll.bak
        docker cp $emby_server_implementations_path $container_id:system
    fi

    # Copy CustomCssJS.js to the system/dashboard-ui/modules directory.
    docker cp $js_path $container_id:system/dashboard-ui/modules

    # Copy the modified app.js into the system/dashboard-ui path
    app_js_path="$(pwd)/res/$emby_version/app.js"
    if [[  -f $app_js_path ]]; then 
        # Backup original app.js to app.js.bak
        docker exec $container_id mv system/dashboard-ui/app.js system/dashboard-ui/app.js.bak
        docker cp $app_js_path $container_id:system/dashboard-ui
    fi

    # Prompts the user to enter whether to restart the container
    read -t 200 -p "Do you want to restart the container? (Enter Y or y to confirm restart, other keys to cancel) " choice

    # Determine if the user input is y or y
    if [[ $choice == "Y" || $choice == "y" ]]; then
        # Restart the Docker container
        docker restart $container_id
        echo "The container has been restarted"
    else
        echo "Please manually restart the container later to take effect"
    fi

    echo "------------- Emby beautify complete ------------\n"
}

# emby rescue
emergency_rescue() {
    # Get the container id/container name/container version of the current emby
    container_id=$(docker ps -a --filter "name=(?i)emby" --format '{{.ID}}' | head -n 1)
    container_name=$(docker inspect -f '{{.Name}}' "$container_id" 2>/dev/null | awk -F '/' '{print $2}')
    emby_version=$(docker inspect -f '{{.Config.Image}}' "$container_id" 2>/dev/null | awk -F ':' '{print $2}')

    if [[ -z "$container_id" || -z "$container_version" ]]; then
        echo "Emby container id or version is empty. Exiting..."
        echo "Please check that the container name contains the string emby (case insensitive)"
        exit 1
    fi

    echo "\nEmby container id: $container_id"
    echo "Emby container name: $container_name"
    echo "Emby container version: $emby_version"

    emby_server_implementations_path="system/Emby.Server.Implementations.dll"
    emby_server_implementations_bak_path="system/Emby.Server.Implementations.dll.bak"
    file_exists=$(docker exec "$container_name_or_id" test -e "$file_path" && echo 1 || echo 0)
    if [[ "$file_exists" -eq 1 ]]; then
        docker exec $container_id rm $emby_server_implementations_path
        docker exec $container_id mv $emby_server_implementations_bak_path $emby_server_implementations_path
    fi

    echo "------------- Emby rescue complete ------------\n"
}

main() {
    echo "Please choose option: "
    echo "0. do nothing"
    echo "1. run emby beauty"
    echo "2. run emby rescue"

    read -t 200 -p "please input number to choose: " choice

    case $choice in
        0)
            ;;
        1)
            emby_beautify
            ;;
        2)
            emergency_rescue
            ;;
        *)
            echo "invalid choose"
            ;;
    esac
}

main