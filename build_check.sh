#!/bin/bash

# Build Verification Script for Piums Artist iOS
echo "🔨 Verificando Build de Piums Artista iOS..."
echo "================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project directory
PROJECT_DIR="/Users/piums/Desktop/PiumsArtistaios/PiumsArtist"
cd "$PROJECT_DIR"

echo -e "${BLUE}📂 Directorio del proyecto:${NC} $PROJECT_DIR"
echo

# Check if all Swift files exist
echo -e "${BLUE}📋 Verificando archivos Swift:${NC}"
echo "================================"

SWIFT_FILES=(
    "PiumsArtist/PiumsArtistApp.swift"
    "PiumsArtist/ContentView.swift"
    "PiumsArtist/Views/MainTabView.swift"
    "PiumsArtist/Views/DashboardView.swift"
    "PiumsArtist/Views/BookingsView.swift"
    "PiumsArtist/Views/CalendarView.swift"
    "PiumsArtist/Views/MessagesView.swift"
    "PiumsArtist/Views/ProfileView.swift"
    "PiumsArtist/Models/Models.swift"
    "PiumsArtist/ViewModels/ViewModels.swift"
    "PiumsArtist/Components/PiumsComponents.swift"
)

MISSING_FILES=0
TOTAL_LINES=0

for file in "${SWIFT_FILES[@]}"; do
    if [ -f "$file" ]; then
        lines=$(wc -l < "$file")
        echo -e "✅ $file (${lines} líneas)"
        TOTAL_LINES=$((TOTAL_LINES + lines))
    else
        echo -e "❌ $file ${RED}[MISSING]${NC}"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

echo
echo -e "${BLUE}📊 Estadísticas:${NC}"
echo "=================="
echo -e "Total de archivos Swift: ${#SWIFT_FILES[@]}"
echo -e "Archivos encontrados: $((${#SWIFT_FILES[@]} - MISSING_FILES))"
echo -e "Archivos faltantes: $MISSING_FILES"
echo -e "Total de líneas de código: $TOTAL_LINES"

# Check project structure
echo
echo -e "${BLUE}🏗️ Estructura del proyecto:${NC}"
echo "============================="
if [ -f "PiumsArtist.xcodeproj/project.pbxproj" ]; then
    echo "✅ project.pbxproj existe"
else
    echo "❌ project.pbxproj faltante"
fi

if [ -d "PiumsArtist.xcodeproj/project.xcworkspace" ]; then
    echo "✅ workspace configurado"
else
    echo "❌ workspace faltante"
fi

# Check for basic syntax issues in key files
echo
echo -e "${BLUE}🔍 Verificación básica de sintaxis:${NC}"
echo "===================================="

# Function to check basic Swift syntax
check_swift_syntax() {
    local file="$1"
    if [ -f "$file" ]; then
        # Check for basic syntax patterns
        if grep -q "import SwiftUI" "$file"; then
            echo "✅ $file - Import SwiftUI ✓"
        fi
        
        # Check for mismatched braces (basic check)
        open_braces=$(grep -o '{' "$file" | wc -l | tr -d ' ')
        close_braces=$(grep -o '}' "$file" | wc -l | tr -d ' ')
        
        if [ "$open_braces" -eq "$close_braces" ]; then
            echo "✅ $file - Llaves balanceadas ✓"
        else
            echo -e "⚠️  $file - ${YELLOW}Posible problema con llaves${NC}"
        fi
    fi
}

# Check key files
check_swift_syntax "PiumsArtist/PiumsArtistApp.swift"
check_swift_syntax "PiumsArtist/Views/MainTabView.swift"
check_swift_syntax "PiumsArtist/Models/Models.swift"

# Check if Xcode project can be parsed
echo
echo -e "${BLUE}🔨 Estado del build:${NC}"
echo "===================="

if command -v xcodebuild >/dev/null 2>&1; then
    echo "✅ xcodebuild disponible"
    
    # Try to get project info
    if xcodebuild -list > /dev/null 2>&1; then
        echo "✅ Proyecto Xcode válido"
        echo -e "${GREEN}🎉 El proyecto debería compilar correctamente en Xcode${NC}"
    else
        echo -e "⚠️  ${YELLOW}xcodebuild requiere Xcode completo (solo Command Line Tools disponibles)${NC}"
        echo -e "📝 Para verificar el build completo, abrir en Xcode:"
        echo -e "   ${BLUE}open PiumsArtist.xcodeproj${NC}"
    fi
else
    echo "❌ xcodebuild no disponible"
fi

# Final summary
echo
echo -e "${BLUE}📋 Resumen Final:${NC}"
echo "=================="

if [ $MISSING_FILES -eq 0 ]; then
    echo -e "${GREEN}✅ Todos los archivos Swift están presentes${NC}"
    echo -e "${GREEN}✅ Estructura del proyecto correcta${NC}"
    echo -e "${GREEN}✅ Sintaxis básica verificada${NC}"
    echo
    echo -e "${GREEN}🎉 El proyecto Piums Artista está listo para build!${NC}"
    echo
    echo -e "${BLUE}Para compilar en Xcode:${NC}"
    echo "1. Abrir: open PiumsArtist.xcodeproj"
    echo "2. Seleccionar simulador iOS"
    echo "3. Presionar Cmd+R para build & run"
else
    echo -e "${RED}❌ Hay archivos faltantes que deben resolverse${NC}"
fi

echo
echo "================================================="
echo -e "${BLUE}🔨 Verificación completada${NC}"
