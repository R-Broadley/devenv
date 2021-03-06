#!/bin/sh

BUILDSCRIPTS="$(realpath $(dirname "$0"))"
REPO="$(dirname "$BUILDSCRIPTS")"
FUNC="$BUILDSCRIPTS/functions"

# Set file locations
CONTAINERFILE="$REPO/Containerfile"

LOCAL="$BUILDSCRIPTS/tmp.sh"
INTERNAL="/tmp/setup.sh"


printf %"s\n\n" "#!/bin/sh" > $LOCAL
cat "$FUNC/ensure_line_in_file.sh" >> $LOCAL
printf %"s\n\n" "touch ~/.profile" >> $LOCAL

# Set environment variables in .profile
source "$BUILDSCRIPTS/env_var_to_profile.sh" >> $LOCAL
# Source .profile in .zprofile
printf %"s\n\n" 'ensure_line_in_file "source $HOME/.profile" $XDG_CONFIG_HOME/zsh/.zprofile' >> $LOCAL

# Set WSL configuration
# Make the default user developer
printf "\n"%"s\n" "sudo sh -c 'echo [user] > /etc/wsl.conf'" >> $LOCAL
printf %"s\n\n" "sudo sh -c 'echo default=developer >> /etc/wsl.conf'" >> $LOCAL
# Allow non-root user to use ping
printf "\n"%"s\n" "sudo setcap cap_net_admin,cap_net_raw+p /usr/bin/ping" >> $LOCAL

chmod +x $LOCAL

CONTAINER=$(\
	docker run -i --detach --entrypoint=sh \
	--security-opt label=disable \
	--mount type=bind,source="$LOCAL",destination="$INTERNAL" \
	devenv\
)
docker exec $CONTAINER sh $INTERNAL
docker export $CONTAINER > devenv.tar
docker stop $CONTAINER > /dev/null
docker rm $CONTAINER > /dev/null

rm $LOCAL
