#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== DevOps Project Sync ===${NC}"

# Verificar si existe el archivo de configuración
if [ ! -f "config/framework.conf" ]; then
    echo -e "${RED}❌ No se encontró el archivo de configuración.${NC}"
    echo -e "${YELLOW}Por favor ejecuta primero: ./setup.sh${NC}"
    exit 1
fi

# Cargar configuración
source config/framework.conf

echo -e "${BLUE}📋 Opciones de sincronización:${NC}"
echo "1) Copiar proyecto del contenedor a local (para editar localmente)"
echo "2) Copiar proyecto local al contenedor (subir cambios)"
echo "3) Reiniciar contenedor con volumen para desarrollo en vivo"
echo ""

read -p "Selecciona una opción (1-3): " sync_option

case $sync_option in
    1)
        echo -e "${YELLOW}📥 Copiando proyecto del contenedor a ./src/${NC}"
        
        # Verificar que el contenedor existe
        if ! docker ps -a --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
            echo -e "${RED}❌ El contenedor $CONTAINER_NAME no existe${NC}"
            echo -e "${BLUE}Ejecuta ./iniciar.sh primero${NC}"
            exit 1
        fi
        
        # Crear directorio local si no existe
        mkdir -p src
        
        # Copiar desde contenedor a local
        docker cp "$CONTAINER_NAME:/app/src/." "./src/"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Proyecto copiado exitosamente a ./src/${NC}"
            echo -e "${BLUE}Ahora puedes editar los archivos localmente${NC}"
        else
            echo -e "${RED}❌ Error al copiar el proyecto${NC}"
        fi
        ;;
        
    2)
        echo -e "${YELLOW}📤 Copiando proyecto local al contenedor${NC}"
        
        if [ ! -d "src" ]; then
            echo -e "${RED}❌ No existe el directorio ./src/${NC}"
            exit 1
        fi
        
        # Copiar de local a contenedor
        docker cp "./src/." "$CONTAINER_NAME:/app/src/"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Proyecto copiado al contenedor${NC}"
            echo -e "${BLUE}Reiniciando contenedor...${NC}"
            docker restart "$CONTAINER_NAME"
        else
            echo -e "${RED}❌ Error al copiar al contenedor${NC}"
        fi
        ;;
        
    3)
        echo -e "${YELLOW}🔄 Reiniciando con desarrollo en vivo...${NC}"
        
        # Detener contenedor actual
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
        
        # Asegurarse de que existe el directorio src y tiene contenido
        if [ ! -f "src/package.json" ]; then
            echo -e "${BLUE}📋 Copiando proyecto base del contenedor...${NC}"
            
            # Crear contenedor temporal para extraer archivos
            temp_container=$(docker run -d "$IMAGE_NAME" tail -f /dev/null)
            mkdir -p src
            docker cp "$temp_container:/app/src/." "./src/"
            docker stop "$temp_container"
            docker rm "$temp_container"
        fi
        
        # Iniciar con volumen para desarrollo en vivo
        echo -e "${BLUE}🚀 Iniciando contenedor con volumen...${NC}"
        docker run -d \
            --name "$CONTAINER_NAME" \
            -p "$PORT:$PORT" \
            -v "$(pwd)/src:/app/src" \
            "$IMAGE_NAME"
            
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Contenedor iniciado con desarrollo en vivo${NC}"
            echo -e "${BLUE}Los cambios en ./src/ se reflejarán automáticamente${NC}"
        else
            echo -e "${RED}❌ Error al iniciar contenedor${NC}"
        fi
        ;;
        
    *)
        echo -e "${RED}❌ Opción inválida${NC}"
        ;;
esac

echo ""
echo -e "${BLUE}Estado actual:${NC}"
docker ps | grep "$CONTAINER_NAME" || echo "Contenedor no está corriendo"