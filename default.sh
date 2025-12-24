#!/bin/bash
set -e
export LANG=C
export LC_ALL=C

### VARIABLES ###

TAB='$\t'
TAB_SIZE='\t'
DISTRO=""

USER_ID=$(id -u "$SUDO_USER")
DBUS_ADDR="unix:path=/run/user/$USER_ID/bus"

# Configuración de repositorio Mozilla
MOZILLA_SOURCES='Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc'

# Configuración de prioridad Mozilla
MOZILLA_PREFERENCES='Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000'

deb_paquetes=(
	brightnessctl
	playerctl
	pipewire
	pipewire-pulse
	pipewire-alsa
	wireplumber
	pamixer
	lm-sensors
	btop
	nm-connection-editor
)

sys_apps=(
	xwayland
	xdg-desktop-portal
	xdg-desktop-portal-wlr
	lxpolkit
	pkexec
	network-manager
)

sway_apps=(
	sway
	waybar
	wofi
	swaybg
	swayidle
	swaylock
	foot
)

gnome_apps=(
	gnome-sushi  --no-install-recommends
	totem --no-install-recommends
	eog --no-install-recommends
	gnome-disk-utility --no-install-recommends
	gnome-text-editor --no-install-recommends
	gnome-calculator --no-install-recommends
	evince --no-install-recommends
	nautilus --no-install-recommends
	baobab --no-install-recommends
)

utils_apps=(
	zip
	unzip
	curl
	grim
	git
	slurp
	dunst
	libnotify-bin
	wl-clipboard
	wf-recorder
	ddcutil
	pavucontrol
)

multimedia_apps=(
    ffmpeg                   # Codecs y conversión de video
    gstreamer1.0-plugins-base
    gstreamer1.0-plugins-good
    gstreamer1.0-plugins-bad
    gstreamer1.0-plugins-ugly
    gstreamer1.0-libav
)

paquetes=(
	"${deb_paquetes[@]}"
	"${sys_apps[@]}"
	"${sway_apps[@]}"
	"${gnome_apps[@]}"
	"${utils_apps[@]}"
	"${multimedia_apps[@]}"
)

### FUNCIONES ###

### Verificar

	ver_sudo() {
		if [ "$EUID" -ne 0 ]; then
			clear
			printf "\t\n"
			printf "\t╔═══════════════════════════════════════════╗\n"
			printf "\t║                                           ║\n"
			printf "\t║ Por favor, ejecuta este script con $ sudo ║\n"
			printf "\t║                                           ║\n"
			printf "\t╚═══════════════════════════════════════════╝\n"
			printf "\t\n"
			exit 1
		fi
	}

	ver_distro(){
		if [ -f /etc/debian_version ]; then
			DISTRO="Debian"
		else
			draw_error "Distro no compatible"
			exit 1
		fi
	}

### Dibujar 

	draw_spinner() {
		local pid=$1
		local text=$2
		local delay=0.1
		local spinstr='|/-\\'
		local total_width=48
		local spinner_len=3
		local msg_width=$(( total_width - spinner_len - 1 ))
		
		while kill -0 "$pid" 2>/dev/null; do
			for (( i=0; i<${#spinstr}; i++ )); do
				printf "\033[F\033[2K"
				printf "║ %-*.*s [%s] ║\n" \
					"$msg_width" "$msg_width" "$text" "${spinstr:i:1}"
				draw_footer
				sleep "$delay"
			done
		done

		# Cuando termine, mostrar “Listo [✔]”
		printf "\033[F\033[2K"
		msg_width=$(( msg_width - 6 ))
		printf "║ %-*.*s %s ║\n\n" "$msg_width" "$msg_width" "$text" "Listo [✔]"
	}

	draw_header(){
		clear
		ancho=30
		largoTitulo=0

		if [[ ${#1}%2 == 0 ]]; then
			largoTitulo=${#1}
		else
			largoTitulo=${#1}+1
		fi

		borde=$(( ($ancho - $largoTitulo) / 2 ))

		centro=""
		for i in $(seq 1 $borde); do
			centro+=" "
		done

		centro+="$1"
		for i in $(seq 1 $borde); do
			centro+=" "
		done

		printf "╔" && printf "═%.0s" {1..10} && printf "%.30s" "$centro" && printf "═%.0s" {1..10} && printf "╗\n"
		printf "║" && printf "%50s" && printf "║\n"
	}

	draw_footer(){
		printf "╚" && printf "═%.0s" {1..34} && printf "leoleguizamon97═╝"
	}

	draw_error(){
		printf "\033[F"
		printf "║ %.37s %$((37 > ${#1} ? 37 - ${#1} : 1))s %s ║\n\n" "$1" "" "Error [x]"
		sleep 1 &
		draw_spinner $! "Saliendo..."
		exit 1
	}

	draw_separator(){
		printf "\033[F"
		printf "╠══════════════════════════════════════════════════╣\n"
	}

	draw_space(){
		printf "\033[F"
		printf "║                                                  ║\n"
		printf "║                                                  ║\n"
	}

### App functions

	sys_invalid(){

		draw_header "Opcion no valida / Cancelado"
		printf "║    La opcion no es valida o fue cancelada.       ║\n"
		printf "║                                                  ║\n"
		draw_footer
	}

### Sistema
	sys_exit(){
		printf "║                                                  ║\n"
		sleep 1 &
		draw_spinner $! "Adios!"
		exit 0
	}

	sys_reboot(){
		printf "\n"
		for i in {5..1}; do
			printf "\033[F║      Reiniciando el sistema en: $i!               ║\n"
			draw_footer
			sleep 1
		done
		sleep 2 &
		draw_spinner $! "Adios!"
		reboot now
	}

	sys_mkDir(){
		# Crear directorios como usuario regular
		sudo -u "$SUDO_USER" mkdir -p /home/"$SUDO_USER"/.config/ > /dev/null
		sudo -u "$SUDO_USER" mkdir -p /home/"$SUDO_USER"/Downloads > /dev/null
		sudo -u "$SUDO_USER" mkdir -p /home/"$SUDO_USER"/Desktop > /dev/null
		sudo -u "$SUDO_USER" mkdir -p /home/"$SUDO_USER"/Documents > /dev/null
		sudo -u "$SUDO_USER" mkdir -p /home/"$SUDO_USER"/Music > /dev/null
		sudo -u "$SUDO_USER" mkdir -p /home/"$SUDO_USER"/Pictures > /dev/null
		sudo -u "$SUDO_USER" mkdir -p /home/"$SUDO_USER"/Videos > /dev/null
		sudo -u "$SUDO_USER" mkdir -p /home/"$SUDO_USER"/Templates > /dev/null
		sudo -u "$SUDO_USER" mkdir -p /home/"$SUDO_USER"/Public > /dev/null

		# Crear el directorio de fuentes
		mkdir -p /usr/local/share/fonts
	}

	sys_update(){
		printf "║    Actualizando repositorios                     ║\n"
		printf "║                                                  ║\n"

		# Actualizar lista de paquetes
		apt update -y > /dev/null 2>&1 &
		draw_spinner $! "Actualizando la lista de paquetes"

		# Fix broken packages
		apt --fix-broken install -y > /dev/null 2>&1 &
		draw_spinner $! "Fixing broken packages"

		# Full Upgrade
		apt full-upgrade -y > /dev/null 2>&1 &
		draw_spinner $! "Actualizando el sistema"

		# Limpiar paquetes obsoletos
		apt autoremove -y > /dev/null 2>&1 &
		draw_spinner $! "Eliminando paquetes obsoletos"
	}

	sys_setNetwork(){
		rm -f /etc/network/interfaces > /dev/null 2>&1 &
		draw_spinner $! "Eliminando configuracion WIFI"
	}

### Install

	install_sway(){
		printf "║    Instalando Entorno Sway                       ║\n"
		printf "║                                                  ║\n"
		
		# Actualizar repositorios
		apt update > /dev/null 2>&1 &
		draw_spinner $! "Actualizando lista de paquetes"
		
		# Verificar e instalar los paquetes disponibles
		draw_space
		for paquete in "${paquetes[@]}"; do
			apt install $paquete -y > /dev/null 2>&1 &
			draw_spinner $! "Instalando $paquete"
		done

		apt autoremove -y > /dev/null 2>&1 &
		draw_spinner $! "Limpiando"

		# Permisos DDCutil
		modprobe i2c-dev
		usermod -aG i2c $SUDO_USER

		# Aviso
		if [ $1 -eq 1 ]; then
			draw_space
			sleep 5 &
			draw_spinner $! "Se recomienda reiniciar el sistema"
		fi
	}

	install_dotfiles(){
		printf "║    Instalando dotfiles                           ║\n"
		printf "║                                                  ║\n"

		sudo -u "$SUDO_USER" git clone https://github.com/leoleguizamon97/dotfiles > /dev/null 2>&1 &
		draw_spinner $! "Descargando Dotfiles"

		sudo rm -rf dotfiles/.git > /dev/null 2>&1 &
		draw_spinner $! "Eliminando .git"

		shopt -s dotglob
		sudo -u "$SUDO_USER" cp -r dotfiles/* /home/"$SUDO_USER"/ > /dev/null 2>&1 &
		draw_spinner $! "Instalando Dotfiles"
		shopt -u dotglob

		sudo rm -rf dotfiles > /dev/null 2>&1 &
		draw_spinner $! "Limpiando"
	}

	install_browser(){
		printf "║    Instalando navegador                          ║\n"
		if [ $1 -eq 1 ]; then
			printf "║                                                  ║\n"
			printf "║    Selecciona un navegador:                      ║\n"
			printf "║                                                  ║\n"
			printf "║     ╔═════════════════════════════════════╗      ║\n"
			printf "║     ║ 1. Brave                            ║      ║\n"
			printf "║     ║ 2. Firefox                          ║      ║\n"
			printf "║     ╚═════════════════════════════════════╝      ║\n"
			printf "║                                                  ║\n"
			printf "║                                                  ║\n"
			printf "║                                                  ║\n"

			draw_footer
			printf "\033[F\033[F"
			read -p "║     Selecciona opcion: " opcion
			printf "\033[F"
			printf "║                                                  ║\n"
		elif [ $1 -eq 0 ]; then
			opcion=1
		fi

			printf "║                                                  ║\n"
		if [ "$opcion" -eq 1 ]; then
			curl -fsS https://dl.brave.com/install.sh | sh > /dev/null 2>&1 &
			draw_spinner $! "Instalando Brave"
		elif [ "$opcion" -eq 2 ]; then
			# Crear directorio para claves APT
			install -d -m 0755 /etc/apt/keyrings > /dev/null 2>&1 &
			draw_spinner $! "Creando directorio de claves"
			
			# Descargar clave de firma de Mozilla
			wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null 2>&1 &
			draw_spinner $! "Descargando clave de Mozilla"
			
			# Agregar repositorio de Mozilla (Debian 13 Trixie)
			echo "$MOZILLA_SOURCES" | tee /etc/apt/sources.list.d/mozilla.sources > /dev/null 2>&1 &
			draw_spinner $! "Agregando repositorio de Mozilla"
			
			# Configurar prioridad de paquetes de Mozilla
			echo "$MOZILLA_PREFERENCES" | tee /etc/apt/preferences.d/mozilla > /dev/null 2>&1 &
			draw_spinner $! "Configurando prioridad de paquetes"
			
			# Actualizar e instalar Firefox
			apt update > /dev/null 2>&1 &
			draw_spinner $! "Actualizando repositorios"
			
			apt install -y firefox > /dev/null 2>&1 &
			draw_spinner $! "Instalando Firefox"
		else
			sys_invalid
		fi
	}

	install_vscodium(){
		printf "║    Instalando VSCodium                           ║\n"
		printf "║                                                  ║\n"

		draw_space

		apt install -y wget > /dev/null 2>&1 &
		draw_spinner $! "Instalando wget"

		apt install -y gpg > /dev/null 2>&1 &
		draw_spinner $! "Instalando gpg"

		apt install -y apt-transport-https > /dev/null 2>&1 &
		draw_spinner $! "Instalando apt-transport-https"
		
		wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg > /dev/null 2>&1 & 
		draw_spinner $! "Descargando clave"
		
		echo -e 'Types: deb\nURIs: https://download.vscodium.com/debs\nSuites: vscodium\nComponents: main\nArchitectures: amd64 arm64\nSigned-by: /usr/share/keyrings/vscodium-archive-keyring.gpg' | sudo tee /etc/apt/sources.list.d/vscodium.sources > /dev/null 2>&1 &
		draw_spinner $! "Agregando repositorio"
		
		apt update > /dev/null 2>&1 &
		draw_spinner $! "Actualizando"

		draw_space
		
		apt install -y codium > /dev/null 2>&1 &
		draw_spinner $! "Instalando VSCodium"
	}

	install_fonts(){
		printf "║    Instalando fuentes                            ║\n"
		printf "║                                                  ║\n"

		FONT_PATH="/tmp/Hasklig.zip"

		# Instalar dependencias
		apt install -y fonts-noto-color-emoji zip unzip > /dev/null 2>&1 &
		draw_spinner $! "Instalando zip y Emoji font"

		# Descargar y descomprimir la fuente Nerd Font Hasklig
		if [ -f "$FONT_PATH" ]; then
			sleep 1 &
			draw_spinner $! "Fuentes ya descargadas!"
		else
			wget -O "$FONT_PATH" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Hasklig.zip > /dev/null 2>&1 &
			draw_spinner $! "Descargando Nerdfont Hasklig"
		fi
		
		unzip -o "$FONT_PATH" -d /usr/local/share/fonts/Hasklig > /dev/null 2>&1 &
		draw_spinner $! "Descomprimiendo Nerdfont Hasklug"
		
		fc-cache -fv > /dev/null 2>&1 &
		draw_spinner $! "Actualizando cache de fuentes"
		
		chmod -R 755 /usr/local/share/fonts > /dev/null
	}

	full_install(){
		printf "║    Instalacion completa de sway                  ║\n"
		printf "║                                                  ║\n"
		printf "║    Solo realizar en instalaciones nuevas         ║\n"
		printf "║    Pensado para instalaciones minimas            ║\n"
		printf "║    (DEBIAN NETINSTALL)                           ║\n"
		printf "║                                                  ║\n"
		draw_footer
		printf "\033[F\033[F"
		read -p "║    ¿Deseas continuar? (s/n): " respuesta
		if [[ "$respuesta" != "s" && "$respuesta" != "S" ]]; then
			sys_invalid
			return
		fi
		draw_space
		draw_separator
		
		# Instalar sway
		install_sway 0
		draw_separator

		# Instalar nerd fonts
		install_fonts
		draw_separator
		
		# Instalar dotfiles
		install_dotfiles
		draw_separator
		
		# Instalar VSCodium
		install_vscodium
		draw_separator
		
		# Instalar Navegadores
		install_browser 0
		draw_separator

		# Establecer tema oscuro
		gtk_setup
		draw_separator

		# Eliminar networkmanager
		sys_setNetwork
		draw_separator

		# Actualizar repositorios
		sys_update
		draw_separator
		printf "║                                                  ║\n"
		# Finalizar
		sleep 2 &
		draw_spinner $! "Instalacion finalizada."
		sleep 3 &
		draw_spinner $! " ¡¡¡Reinicia el sistema!!! "
	}

### GTK

	gtk_setup(){
		printf "║    Configurando GTK                              ║\n"
		printf "║                                                  ║\n"
		
		# Establecer tema oscuro gnome apps
		sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR" gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' > /dev/null 2>&1 &
		draw_spinner $! "Estableciendo tema oscuro"

		sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR" xdg-user-dirs-update > /dev/null 2>&1 &
		draw_spinner $! "Actualizando directorios de usuario"

		sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR" gsettings set org.gnome.desktop.privacy remember-recent-files false > /dev/null 2>&1 &
		draw_spinner $! "Deshabilitando archivos recientes"
	}

	gtk_dracula(){
		printf "║    Instalando tema Dracula                       ║\n"
		printf "║                                                  ║\n"

		# Crear directorios necesarios
		sudo -u "$SUDO_USER" mkdir -p /home/"$SUDO_USER"/.themes > /dev/null 2>&1
		sudo -u "$SUDO_USER" mkdir -p /home/"$SUDO_USER"/.icons > /dev/null 2>&1

		cd /tmp || exit 1

		# Descargar tema GTK Dracula
		wget -O dracula-gtk.zip https://github.com/dracula/gtk/archive/master.zip > /dev/null 2>&1 &
		draw_spinner $! "Descargando tema Dracula GTK"

		# Descargar iconos Dracula
		wget -O dracula-icons.zip https://github.com/dracula/gtk/files/5214870/Dracula.zip > /dev/null 2>&1 &
		draw_spinner $! "Descargando iconos Dracula"

		# Descomprimir tema GTK
		unzip -o dracula-gtk.zip > /dev/null 2>&1 &
		draw_spinner $! "Descomprimiendo tema GTK"

		# Mover tema a .themes con el nombre correcto
		if [ -d "gtk-master" ]; then
			mv gtk-master /home/"$SUDO_USER"/.themes/Dracula > /dev/null 2>&1 &
			draw_spinner $! "Instalando tema Dracula"
		fi

		# Descomprimir iconos
		unzip -o dracula-icons.zip -d /home/"$SUDO_USER"/.icons/ > /dev/null 2>&1 &
		draw_spinner $! "Instalando iconos Dracula"

		# Descargar libadwaita-theme-changer
		sudo -u "$SUDO_USER" git clone https://github.com/odziom91/libadwaita-theme-changer > /dev/null 2>&1 &
		draw_spinner $! "Descargando libadwaita-theme-changer"

		# Ejecutar el instalador de libadwaita
		if [ -d "libadwaita-theme-changer" ]; then
			cd libadwaita-theme-changer || exit 1
			sudo -u "$SUDO_USER" python3 libadwaita-theme-changer.py > /dev/null 2>&1 &
			draw_spinner $! "Aplicando tema a libadwaita"
			cd /tmp || exit 1
		fi

		draw_space

		# Aplicar tema con gsettings
		sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR" gsettings set org.gnome.desktop.interface icon-theme "Dracula" > /dev/null 2>&1 &
		draw_spinner $! "Aplicando iconos Dracula"

		sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR" gsettings set org.gnome.desktop.wm.preferences theme "Dracula" > /dev/null 2>&1 &
		draw_spinner $! "Aplicando tema de ventanas Dracula"

		sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR" gsettings set org.gnome.desktop.interface gtk-theme "Dracula" > /dev/null 2>&1 &
		draw_spinner $! "Aplicando tema GTK Dracula"

		# Limpiar archivos temporales
		cd /tmp || exit 1
		rm -rf dracula-gtk.zip dracula-icons.zip gtk-master libadwaita-theme-changer > /dev/null 2>&1 &
		draw_spinner $! "Limpiando archivos temporales"

		cd - > /dev/null || exit 1
}

### FUNCIONES PENDIENTES ###

### Main menu

	main(){
		while true; do
			draw_header "Instalador de SWAY"
			printf "║      Selecciona una opcion:                      ║\n"
			printf "║                                                  ║\n"
			printf "║     ╔═════════════════════════════════════╗      ║\n"
			printf "║     ║ 1. Instalar LeOS (Full install)     ║      ║\n"
			printf "║     ╠═════════════════════════════════════╣      ║\n"
			printf "║     ║ 2. Instalar Sway                    ║      ║\n"
			printf "║     ║ 3. Copiar dotfiles                  ║      ║\n"
			printf "║     ║ 4. Actualizar sistema               ║      ║\n"
			printf "║     ╠═════════════════════════════════════╣      ║\n"
			printf "║     ║ 5. Configurar GTK                   ║      ║\n"
			printf "║     ║ D. Usar tema Dracula                ║      ║\n"
			printf "║     ╠═════════════════════════════════════╣      ║\n"
			printf "║     ║ 6. Instalar VS Codium               ║      ║\n"	
			printf "║     ║ 7. Instalar Navegador               ║      ║\n"
			printf "║     ║ 8. Instalar Fuentes                 ║      ║\n"
			printf "║     ╠═════════════════════════════════════╣      ║\n"
			printf "║     ║ 9. Reiniciar el sistema             ║      ║\n"
			printf "║     ║ 0. Salir                            ║      ║\n"
			printf "║     ╚═════════════════════════════════════╝      ║\n"
			printf "║                                                  ║\n"
			printf "║     %.40s %*s ║\n" "$DISTRO" $(( ${#DISTRO} < 43 ? 43 - ${#DISTRO} : 3  )) ""
			printf "║                                                  ║\n"
			printf "║                                                  ║\n"
			draw_footer
			printf "\033[F\033[F"
			read -p "║     Selecciona opcion: " opcion
			if [ "$opcion" == "1" ]; then
				draw_header "$DISTRO - LeOS Edition"
				full_install
			elif [ "$opcion" == "2" ]; then
				draw_header "Instalando Escritorio Sway"
				install_sway 1
			elif [ "$opcion" == "3" ]; then
				draw_header "Descarga de dotfiles"
				install_dotfiles
			elif [ "$opcion" == "4" ]; then
				draw_header "Actualizando $DISTRO"
				sys_update
			elif [ "$opcion" == "5" ]; then
				draw_header "Configurar GTK"
				gtk_setup
			elif [ "$opcion" == "D" ]; then
				draw_header "Configurar Tema Dracula"
				gtk_dracula
			elif [ "$opcion" == "6" ]; then
				draw_header "Instalando VSCodium"
				install_vscodium
			elif [ "$opcion" == "7" ]; then
				draw_header "Instalando Navegador"
				install_browser 1
			elif [ "$opcion" == "8" ]; then
				draw_header "Instalando Fuentes"
				install_fonts
			elif [ "$opcion" == "9" ]; then
				draw_header "Reiniciando el sistema"
				sys_reboot
			elif [ "$opcion" == "0" ]; then
				draw_header "Saliendo..."
				sys_exit
			else
				sys_invalid
			fi
			sleep 3
		done
	}

### MAIN ###

draw_header "Verificando..."
printf "║                                                  ║\n"

sleep 0.2 &
draw_spinner $! "Verificando permisos de sudo..."
ver_sudo

sudo rm -rf .git 2>/dev/null

sleep 0.2 &
draw_spinner $! "Verificando distribucion..."
ver_distro

sleep 0.2 &
draw_spinner $! "Creando carpetas de usuario..."
sys_mkDir

cd /home/"$SUDO_USER"/Desktop/

sleep 1
main
