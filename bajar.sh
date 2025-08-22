#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== DevOps Container Shutdown ===${NC}"

# Verificar si existe el archivo de configuración
if [ ! -f "config/framework.conf" ]; then
    echo -e "${RED}❌ No se encontró el archivo de configuración.${NC}"
    echo -e "${YELLOW}Por favor ejecuta primero: ./setup.sh${NC}"
    exit 1
fi

# Cargar configuración
source config/framework.conf

echo -e "${BLUE}📋 Opciones de parada:${NC}"
echo "1) Solo detener el contenedor (mantener para reiniciar después)"
echo "2) Detener y eliminar contenedor (mantener imagen)"
echo "3) Limpieza completa (detener, eliminar contenedor e imagen)"
echo "4) Mostrar estado actual"
echo ""

read -p "Selecciona una opción (1-4): " shutdown_option

case $shutdown_option in
    1)
        echo -e "${YELLOW}⏸️  Deteniendo contenedor $CONTAINER_NAME...${NC}"
        
        if docker ps -q -f name="$CONTAINER_NAME" > /dev/null; then
            docker stop "$CONTAINER_NAME"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Contenedor detenido exitosamente${NC}"
                echo -e "${BLUE}💡 Puedes reiniciarlo con: docker start $CONTAINER_NAME${NC}"
            else
                echo -e "${RED}❌ Error al detener el contenedor${NC}"
            fi
        else
            echo -e "${YELLOW}ℹ️  El contenedor no está ejecutándose${NC}"
        fi
        ;;
        
    2)
        echo -e "${YELLOW}🛑 Deteniendo y eliminando contenedor $CONTAINER_NAME...${NC}"
        
        # Detener si está corriendo
        if docker ps -q -f name="$CONTAINER_NAME" > /dev/null; then
            docker stop "$CONTAINER_NAME"
            echo -e "${GREEN}✅ Contenedor detenido${NC}"
        fi
        
        # Eliminar contenedor
        if docker ps -aq -f name="$CONTAINER_NAME" > /dev/null; then
            docker rm "$CONTAINER_NAME"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Contenedor eliminado${NC}"
                echo -e "${BLUE}💡 La imagen $IMAGE_NAME se mantiene para uso futuro${NC}"
                echo -e "${BLUE}💡 Puedes recrearlo con: ./iniciar.sh${NC}"
            else
                echo -e "${RED}❌ Error al eliminar el contenedor${NC}"
            fi
        else
            echo -e "${YELLOW}ℹ️  El contenedor no existe${NC}"
        fi
        ;;
        
    3)
        echo -e "${YELLOW}🧹 Limpieza completa del proyecto $FRAMEWORK...${NC}"
        
        # Detener contenedor
        if docker ps -q -f name="$CONTAINER_NAME" > /dev/null; then
            docker stop "$CONTAINER_NAME"
            echo -e "${GREEN}✅ Contenedor detenido${NC}"
        fi
        
        # Eliminar contenedor
        if docker ps -aq -f name="$CONTAINER_NAME" > /dev/null; then
            docker rm "$CONTAINER_NAME"
            echo -e "${GREEN}✅ Contenedor eliminado${NC}"
        fi
        
        # Eliminar imagen
        if docker images -q "$IMAGE_NAME" > /dev/null; then
            docker rmi "$IMAGE_NAME"
            echo -e "${GREEN}✅ Imagen eliminada${NC}"
        fi
        
        # Preguntar si eliminar archivos locales
        if [ -d "src" ]; then
            echo ""
            read -p "¿También eliminar archivos locales en ./src/? (y/n): " delete_local
            if [[ $delete_local =~ ^[Yy]$ ]]; then
                rm -rf src/
                echo -e "${GREEN}✅ Archivos locales eliminados${NC}"
            fi
        fi
        
        echo -e "${GREEN}🎉 Limpieza completa terminada${NC}"
        echo -e "${BLUE}💡 Para empezar de nuevo: ./setup.sh && ./iniciar.sh${NC}"
        ;;
        
    4)
        echo -e "${BLUE}📊 Estado actual del proyecto $FRAMEWORK:${NC}"
        echo ""
        
        # Mostrar configuración
        echo -e "${YELLOW}=== Configuración ===${NC}"
        echo "Framework: $FRAMEWORK"
        echo "Puerto: $PORT"
        echo "Contenedor: $CONTAINER_NAME"
        echo "Imagen: $IMAGE_NAME"
        echo ""
        
        # Estado del contenedor
        echo -e "${YELLOW}=== Estado del contenedor ===${NC}"
        if docker ps -f name="$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "$CONTAINER_NAME"; then
            docker ps -f name="$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
            echo -e "${GREEN}✅ Contenedor ejecutándose${NC}"
            echo -e "${BLUE}🌐 Aplicación disponible en: http://localhost:$PORT${NC}"
        elif docker ps -a -f name="$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}" | grep -q "$CONTAINER_NAME"; then
            docker ps -a -f name="$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}"
            echo -e "${YELLOW}⏸️  Contenedor detenido${NC}"
            echo -e "${BLUE}💡 Reiniciar con: docker start $CONTAINER_NAME${NC}"
        else
            echo -e "${RED}❌ Contenedor no existe${NC}"
        fi
        echo ""
        
        # Estado de la imagen
        echo -e "${YELLOW}=== Estado de la imagen ===${NC}"
        if docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -q "$IMAGE_NAME"; then
            docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
            echo -e "${GREEN}✅ Imagen disponible${NC}"
        else
            echo -e "${RED}❌ Imagen no existe${NC}"
            echo -e "${BLUE}💡 Construir con: ./iniciar.sh${NC}"
        fi
        echo ""
        
        # Archivos locales
        echo -e "${YELLOW}=== Archivos locales ===${NC}"
        if [ -d "src" ] && [ "$(ls -A src 2>/dev/null)" ]; then
            echo -e "${GREEN}✅ Archivos locales disponibles en ./src/${NC}"
            echo "Contenido principal:"
            ls -la src/ | head -10
        else
            echo -e "${YELLOW}⚠️  No hay archivos locales en ./src/${NC}"
            echo -e "${BLUE}💡 Sincronizar con: ./sync.sh${NC}"
        fi
        ;;
        
    *)
        echo -e "${RED}❌ Opción inválida${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}=== Comandos útiles ===${NC}"
echo "Ver todos los contenedores: docker ps -a"
echo "Ver todas las imágenes: docker images"
echo "Logs del contenedor: docker logs $CONTAINER_NAME"
echo "Reiniciar todo: ./setup.sh && ./iniciar.sh"