# /bin/bash

plugin_path="$(pwd)/plugin/Emby.CustomCssJS.dll"
js_path="$(pwd)/res/CustomCssJS.js"

# Prompt the user for the Emby container name
read -p "Please input emby container name(eg: Emby): " container_name

# Prompt the user for the Emby version number
read -p "Please input emby container version(eg: 4.7.11.0): " emby_version

# Print Emby container name and version number
echo "Emby container name: $container_name"
echo "Emby container version: $emby_version"

# Get the container id of the current emby
container_id=$(docker ps -aqf "name=$container_name")
echo "Emby container id: $container_id"

# Copy Emby.CustomCssJS.dll to the /config/plugins directory
docker cp $plugin_path $container_id:config/plugins

# Copy CustomCssJS.js to the system/dashboard-ui/modules directory.
docker cp $js_path $container_id:system/dashboard-ui/modules

# Backup original app.js to app.js.bak
docker exec $container_id mv system/dashboard-ui/app.js system/dashboard-ui/app.js.bak

# Copy the modified app.js into the system/dashboard-ui path
app_js_path="$(pwd)/res/$emby_version/app.js"
if [[ ! -f $app_js_path ]]; then 
	echo "Not yet adapted to the current version, please wait for the update"
	exit 0
fi
docker cp "res/$emby_version/app.js" $container_id:system/dashboard-ui

# Prompts the user to enter whether to restart the container
read -p "Do you want to restart the container? (Enter Y or y to confirm reboot, other keys to cancel) " choice

# Determine if the user input is y or y
if [[ $choice == "Y" || $choice == "y" ]]; then
    # Restart the Docker container
    docker restart $container_id
    echo "The container has been restarted"
else
    echo "Please manually restart the container later to take effect"
fi
