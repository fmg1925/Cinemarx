# Cinemarx - Ruby on Rails

Este es un proyecto web desarrollado en **Ruby on Rails** que permite explorar un catálogo de películas utilizando la API de [The Movie Database (TMDb)](https://www.themoviedb.org/). La aplicación ofrece funcionalidades como búsqueda y gestión de usuarios.

## Características

- **Búsqueda de películas** mediante la API de TMDb.
- **Gestión de usuarios** (base de datos local): crear, editar y eliminar cuentas.
- **Ratings de Películas** mediante la API de TMDb + Ratings de usuarios locales.
- **Idiomas:** Interfaz y búsqueda disponibles en Español e Inglés.
- Interfaz clara y sencilla para la exploración del catálogo.
  
## Tecnologías utilizadas

- **Ruby 3.3.8**
- **Rails 8.0.2**
- **The Movie DB API**
- **PostgreSQL**
- **HTML/CSS**
- **JavaScript**

## Pre-requisitos
- **Para Windows**:
    **WSL2 (Debian/Ubuntu):**
    https://wiki.debian.org/InstallingDebianOn/Microsoft/Windows/SubsystemForLinux

    **Dentro de WSL/Linux:**

    ```bash
    sudo apt update
    sudo apt install -y rbenv ruby-build git postgresql libpq-dev libffi-dev libyaml-dev redis-server
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    ~/.rbenv/bin/rbenv init
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    source ~/.bashrc
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
    rbenv install 3.3.8
    rbenv global 3.3.8
    rbenv rehash
    gem install rails
    sudo -u postgres psql # Cambiar la contraseña de postgres
    ALTER USER postgres with encrypted password 'your_password'; # Tu contraseña aquí
    exit # Salir de la consola de postgres
    ```

## Instalación y uso

1. **Clona el repositorio:**

   ```bash
   git clone https://github.com/fmg1925/Cinemarx.git ~/Cinemarx
   cd ~/Cinemarx
   ```

2. **Instalar las dependencias:**
    ```bash
    bundle install
    ```

3. **Configura el archivo `config/database.yml`:**

    Copia el archivo de ejemplo:
    ```bash
    cp config/database.example.yml config/database.yml
    ```

    **Edita las siguientes líneas con tus credenciales si es necesario:**
    ```yml
    username: postgres
    password: your_password
    host: localhost
    ```

4. **Configurar la base de datos:**
    ```bash
    rails db:create
    rails db:migrate
    rails db:seed # Para generar usuarios de prueba
    ```

5. **Agregar API Key y Token de TMDb:**

    Crea un archivo **.env** y agrega:

    ```env
    API_KEY=TU_KEY_AQUÍ
    TOKEN=TU_TOKEN_AQUÍ
    ```

Este proyecto utiliza **Sidekiq** para ejecutar tareas en segundo plano.

6. **Iniciar Sidekiq:**
    ```bash
    bundle exec sidekiq -C config/sidekiq.yml
    ```

7. **Iniciar el servidor en una nueva terminal o instancia de WSL:**
    ```bash
    ~/Cinemarx/bin/rails server
    ```

8. **Visita `http://localhost:3000` en tu navegador.**

Usuario de Ejemplo:
**Nombre de Usuario:** admin
**Contraseña:** secret12
