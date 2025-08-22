#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== DevOps Debug Tool ===${NC}"

# Verificar si existe el archivo de configuración
if [ ! -f "config/framework.conf" ]; then
    echo -e "${RED}❌ No se encontró el archivo de configuración.${NC}"
    echo -e "${YELLOW}Por favor ejecuta primero: ./setup.sh${NC}"
    exit 1
fi

# Cargar configuración
source config/framework.conf

echo -e "${BLUE}📊 Estado actual del sistema:${NC}"
echo ""

# Mostrar configuración
echo -e "${YELLOW}=== Configuración actual ===${NC}"
cat config/framework.conf
echo ""

# Verificar Docker
echo -e "${YELLOW}=== Estado de Docker ===${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker no está instalado${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Docker está instalado${NC}"
    docker version --format 'Versión: {{.Client.Version}}'
fi
echo ""

# Mostrar imágenes
echo -e "${YELLOW}=== Imágenes Docker ===${NC}"
docker images | head -1
docker images | grep -E "(devops-|$IMAGE_NAME)" || echo "No hay imágenes relacionadas"
echo ""

# Mostrar contenedores
echo -e "${YELLOW}=== Contenedores Docker ===${NC}"
docker ps -a | head -1
docker ps -a | grep -E "(devops-|$CONTAINER_NAME)" || echo "No hay contenedores relacionados"
echo ""

# Verificar puertos
echo -e "${YELLOW}=== Verificar puerto $PORT ===${NC}"
if lsof -i :$PORT > /dev/null 2>&1; then
    echo -e "${RED}⚠️  Puerto $PORT está en uso:${NC}"
    lsof -i :$PORT
else
    echo -e "${GREEN}✅ Puerto $PORT está disponible${NC}"
fi
echo ""

# Comandos útiles
echo -e "${YELLOW}=== Comandos útiles ===${NC}"
echo "Limpiar todo:"
echo "  docker stop $CONTAINER_NAME 2>/dev/null || true"
echo "  docker rm $CONTAINER_NAME 2>/dev/null || true"
echo "  docker rmi $IMAGE_NAME 2>/dev/null || true"
echo ""
echo "Construir manualmente:"
echo "  docker build -f Dockerfile.$FRAMEWORK -t $IMAGE_NAME ."
echo ""
echo "Ejecutar manualmente:"
echo "  docker run -d --name $CONTAINER_NAME -p $PORT:$PORT $IMAGE_NAME"
echo ""
echo "Ver logs:"
echo "  docker logs $CONTAINER_NAME"
echo ""

# Función de limpieza automática
echo -e "${BLUE}¿Quieres hacer una limpieza completa? (y/n): ${NC}" 
read -r cleanup_choice
if [[ $cleanup_choice =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🧹 Haciendo limpieza completa...${NC}"
    
    # Detener todos los contenedores relacionados
    docker ps -q --filter "name=devops-" | xargs -r docker stop
    
    # Remover todos los contenedores relacionados
    docker ps -aq --filter "name=devops-" | xargs -r docker rm
    
    # Remover todas las imágenes relacionadas
    docker images -q --filter "reference=devops-*" | xargs -r docker rmi
    
    echo -e "${GREEN}✅ Limpieza completa terminada${NC}"
    echo -e "${BLUE}Ahora puedes ejecutar: ./setup.sh && ./iniciar.sh${NC}"
fi