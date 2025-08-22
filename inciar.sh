#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== DevOps Container Initializer ===${NC}"

# Verificar si existe el archivo de configuración
if [ ! -f "config/framework.conf" ]; then
    echo -e "${RED}❌ No se encontró el archivo de configuración.${NC}"
    echo -e "${YELLOW}Por favor ejecuta primero: ./setup.sh${NC}"
    exit 1
fi

# Cargar configuración
source config/framework.conf

echo -e "${BLUE}📖 Cargando configuración...${NC}"
echo "Framework: $FRAMEWORK"
echo "Puerto: $PORT"
echo "Imagen: $IMAGE_NAME"
echo "Contenedor: $CONTAINER_NAME"
echo ""

# Función para limpiar contenedores y imágenes existentes
cleanup() {
    echo -e "${YELLOW}🧹 Limpiando contenedores e imágenes existentes...${NC}"
    
    # Detener contenedor si está corriendo
    if [ $(docker ps -q -f name=$CONTAINER_NAME) ]; then
        echo "Deteniendo contenedor existente..."
        docker stop $CONTAINER_NAME
    fi
    
    # Remover contenedor si existe
    if [ $(docker ps -aq -f name=$CONTAINER_NAME) ]; then
        echo "Removiendo contenedor existente..."
        docker rm $CONTAINER_NAME
    fi
    
    # Remover imagen si existe
    if [ $(docker images -q $IMAGE_NAME) ]; then
        echo "Removiendo imagen existente..."
        docker rmi $IMAGE_NAME
    fi
}

# Preguntar si quiere hacer cleanup
read -p "¿Quieres limpiar contenedores e imágenes existentes? (y/n): " do_cleanup
if [[ $do_cleanup =~ ^[Yy]$ ]]; then
    cleanup
fi

echo -e "${BLUE}🔨 Construyendo imagen Docker para $FRAMEWORK...${NC}"

# Construir imagen según el framework
if [ "$FRAMEWORK" = "angular" ]; then
    docker build -f Dockerfile.angular -t $IMAGE_NAME .
elif [ "$FRAMEWORK" = "react" ]; then
    docker build -f Dockerfile.react -t $IMAGE_NAME .
else
    echo -e "${RED}❌ Framework no soportado: $FRAMEWORK${NC}"
    exit 1
fi

# Verificar si la construcción fue exitosa
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Imagen construida exitosamente!${NC}"
else
    echo -e "${RED}❌ Error al construir la imagen${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 Iniciando contenedor...${NC}"

# Debug: mostrar variables
echo -e "${BLUE}🔍 Debug - Variables:${NC}"
echo "CONTAINER_NAME: '$CONTAINER_NAME'"
echo "PORT: '$PORT'"
echo "IMAGE_NAME: '$IMAGE_NAME'"
echo "PWD: '$(pwd)'"
echo ""

# Crear directorio src si no existe
mkdir -p src

# Verificar y crear estructura básica si es necesario
if [ ! -f "src/package.json" ] && [ "$FRAMEWORK" = "react" ]; then
    echo -e "${YELLOW}📁 Creando estructura básica de React en ./src/${NC}"
    # La aplicación ya se creó dentro del contenedor, solo creamos el directorio local
elif [ ! -f "src/package.json" ] && [ "$FRAMEWORK" = "angular" ]; then
    echo -e "${YELLOW}📁 Creando estructura básica de Angular en ./src/${NC}"
    # La aplicación ya se creó dentro del contenedor, solo creamos el directorio local
fi

# Ejecutar contenedor
echo -e "${BLUE}Ejecutando comando Docker...${NC}"
docker run -d \
    --name "$CONTAINER_NAME" \
    -p "$PORT:$PORT" \
    "$IMAGE_NAME"

# Verificar si el contenedor se inició correctamente
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Contenedor iniciado exitosamente!${NC}"
    echo ""
    echo -e "${YELLOW}=== Información del contenedor ===${NC}"
    echo "Nombre: $CONTAINER_NAME"
    echo "Puerto: http://localhost:$PORT"
    echo "Framework: $FRAMEWORK"
    echo ""
    echo -e "${BLUE}📋 Comandos útiles:${NC}"
    echo "Ver logs: docker logs $CONTAINER_NAME"
    echo "Entrar al contenedor: docker exec -it $CONTAINER_NAME /bin/bash"
    echo "Detener: docker stop $CONTAINER_NAME"
    echo "Reiniciar: docker restart $CONTAINER_NAME"
    echo ""
    echo -e "${GREEN}🌐 Tu aplicación estará disponible en: http://localhost:$PORT${NC}"
else
    echo -e "${RED}❌ Error al iniciar el contenedor${NC}"
    exit 1
fi

# Mostrar estado del contenedor
echo -e "${BLUE}📊 Estado actual:${NC}"
docker ps | grep $CONTAINER_NAME