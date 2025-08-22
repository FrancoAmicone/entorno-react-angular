#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Crear directorio config si no existe
mkdir -p config

echo -e "${BLUE}=== DevOps Framework Setup ===${NC}"
echo -e "${YELLOW}Selecciona tu framework de desarrollo:${NC}"
echo ""
echo "1) Angular"
echo "2) React"
echo ""

# Función para validar entrada
validate_choice() {
    if [[ $1 =~ ^[1-2]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Loop hasta obtener una opción válida
while true; do
    read -p "Ingresa tu opción (1 o 2): " choice
    
    if validate_choice $choice; then
        break
    else
        echo -e "${RED}❌ Opción inválida. Por favor selecciona 1 o 2.${NC}"
    fi
done

# Procesar la elección
case $choice in
    1)
        framework="angular"
        version="17"
        port="4200"
        echo -e "${GREEN}✅ Has seleccionado Angular${NC}"
        ;;
    2)
        framework="react"
        version="18"
        port="3000"
        echo -e "${GREEN}✅ Has seleccionado React${NC}"
        ;;
esac

# Guardar configuración
cat > config/framework.conf << EOF
FRAMEWORK=$framework
VERSION=$version
PORT=$port
PROJECT_NAME=mi-app-$framework
CONTAINER_NAME=devops-$framework-container
IMAGE_NAME=devops-$framework-image
EOF

echo -e "${BLUE}📝 Configuración guardada en config/framework.conf${NC}"
echo -e "${GREEN}🚀 Setup completado! Ahora puedes ejecutar ./iniciar.sh${NC}"

# Mostrar resumen
echo ""
echo -e "${YELLOW}=== Resumen de configuración ===${NC}"
echo "Framework: $framework"
echo "Puerto: $port"
echo "Nombre del proyecto: mi-app-$framework"
echo ""
echo -e "${BLUE}Próximo paso: ejecuta ${YELLOW}./iniciar.sh${BLUE} para construir e iniciar el contenedor${NC}"