#!/bin/bash
# =============================================================================
# setup_ios_faceid.sh
# Añade el permiso NSFaceIDUsageDescription al Info.plist de iOS
# para que la autenticación con Face ID funcione sin que la app crashee.
#
# INSTRUCCIONES (ejecutar en Mac desde la carpeta raíz del proyecto):
#   chmod +x setup_ios_faceid.sh
#   ./setup_ios_faceid.sh
# =============================================================================

PLIST_PATH="ios/Runner/Info.plist"

if [ ! -f "$PLIST_PATH" ]; then
  echo "❌ Error: No se encontró $PLIST_PATH"
  echo "   Asegúrate de ejecutar este script desde la carpeta raíz del proyecto Flutter."
  exit 1
fi

# Comprobar si la clave ya existe para no duplicarla
if grep -q "NSFaceIDUsageDescription" "$PLIST_PATH"; then
  echo "✅ NSFaceIDUsageDescription ya está configurado en $PLIST_PATH"
  echo "   No es necesario hacer nada más."
  exit 0
fi

# Insertar la clave justo antes de </dict> al final del archivo
/usr/libexec/PlistBuddy -c "Add :NSFaceIDUsageDescription string 'Esta aplicación usa el Face ID para iniciar sesión de forma segura y rápida.'" "$PLIST_PATH"

if [ $? -eq 0 ]; then
  echo "✅ Permiso de Face ID añadido correctamente a $PLIST_PATH"
  echo ""
  echo "   Ahora puedes compilar la app con:"
  echo "   flutter run"
  echo "   (o desde Xcode)"
else
  echo "❌ Error al añadir la clave. Intentando con método alternativo..."
  
  # Método alternativo: edición directa del XML
  sed -i '' 's|</dict>|  <key>NSFaceIDUsageDescription</key>\n\t<string>Esta aplicación usa el Face ID para iniciar sesión de forma segura y rápida.</string>\n</dict>|' "$PLIST_PATH"

  if grep -q "NSFaceIDUsageDescription" "$PLIST_PATH"; then
    echo "✅ Permiso de Face ID añadido correctamente (método alternativo)."
    echo ""
    echo "   Ahora puedes compilar la app con:"
    echo "   flutter run"
  else
    echo "❌ No se pudo añadir automáticamente."
    echo "   Añade manualmente estas 2 líneas en ios/Runner/Info.plist antes de </dict>:"
    echo ""
    echo "   <key>NSFaceIDUsageDescription</key>"
    echo "   <string>Esta aplicación usa el Face ID para iniciar sesión de forma segura y rápida.</string>"
  fi
fi
