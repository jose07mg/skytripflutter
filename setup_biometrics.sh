#!/bin/bash
# =============================================================================
# setup_biometrics.sh
# Configura Face ID (iOS) y Huella/BiometricAuth (Android) automáticamente.
#
# INSTRUCCIONES (ejecutar en Mac desde la carpeta raíz del proyecto):
#   chmod +x setup_biometrics.sh
#   ./setup_biometrics.sh
# =============================================================================

echo "======================================"
echo " Configuración de Biometría (RMS DAM)"
echo "======================================"
echo ""

# Detectar sistema operativo para compatibilidad de 'sed'
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE=(sed -i '')
else
  SED_INPLACE=(sed -i)
fi

# ─── iOS: NSFaceIDUsageDescription ───────────────────────────────────────────
PLIST="ios/Runner/Info.plist"

if [ ! -f "$PLIST" ]; then
  echo "⚠️  iOS: No se encontró $PLIST (omitiendo configuración iOS)"
else
  if grep -q "NSFaceIDUsageDescription" "$PLIST"; then
    echo "✅ iOS: NSFaceIDUsageDescription ya está configurado."
  else
    /usr/libexec/PlistBuddy -c "Add :NSFaceIDUsageDescription string 'Esta aplicación usa Face ID para iniciar sesión de forma segura.'" "$PLIST" 2>/dev/null
    if grep -q "NSFaceIDUsageDescription" "$PLIST"; then
      echo "✅ iOS: Permiso Face ID añadido correctamente."
    else
      # Método alternativo con sed
      "${SED_INPLACE[@]}" 's|</dict>|  <key>NSFaceIDUsageDescription</key>\'$'\n''  <string>Esta aplicación usa Face ID para iniciar sesión de forma segura.</string>\'$'\n''</dict>|' "$PLIST"
      echo "✅ iOS: Permiso Face ID añadido (método alternativo)."
    fi
  fi
fi

echo ""

# ─── Android: Permisos en AndroidManifest.xml ────────────────────────────────
MANIFEST="android/app/src/main/AndroidManifest.xml"

if [ ! -f "$MANIFEST" ]; then
  echo "⚠️  Android: No se encontró $MANIFEST (omitiendo configuración Android)"
else
  if grep -q "USE_BIOMETRIC" "$MANIFEST"; then
    echo "✅ Android: Permiso USE_BIOMETRIC ya configurado."
  else
    # Insertar permisos justo antes de <application
    "${SED_INPLACE[@]}" 's|<application|<uses-permission android:name="android.permission.USE_BIOMETRIC"/>\'$'\n''    <uses-permission android:name="android.permission.USE_FINGERPRINT"/>\'$'\n''    <application|' "$MANIFEST"
    echo "✅ Android: Permisos USE_BIOMETRIC y USE_FINGERPRINT añadidos."
  fi
fi

# ─── Android: Cambiar MainActivity a FlutterFragmentActivity ─────────────────
MAIN_ACTIVITY=$(find android/app/src/main -name "MainActivity.kt" 2>/dev/null | head -n 1)

if [ -z "$MAIN_ACTIVITY" ]; then
  MAIN_ACTIVITY=$(find android/app/src/main -name "MainActivity.java" 2>/dev/null | head -n 1)
fi

if [ -z "$MAIN_ACTIVITY" ]; then
  echo "⚠️  Android: No se encontró MainActivity.kt/java"
else
  if grep -q "FlutterFragmentActivity" "$MAIN_ACTIVITY"; then
    echo "✅ Android: MainActivity ya usa FlutterFragmentActivity."
  else
    # Cambiar FlutterActivity por FlutterFragmentActivity
    "${SED_INPLACE[@]}" 's|io.flutter.embedding.android.FlutterActivity|io.flutter.embedding.android.FlutterFragmentActivity|g' "$MAIN_ACTIVITY"
    "${SED_INPLACE[@]}" 's|FlutterActivity()|FlutterFragmentActivity()|g' "$MAIN_ACTIVITY"
    "${SED_INPLACE[@]}" 's|extends FlutterActivity|extends FlutterFragmentActivity|g' "$MAIN_ACTIVITY"
    echo "✅ Android: MainActivity actualizada a FlutterFragmentActivity."
  fi
fi

echo ""
echo "======================================"
echo " ¡Configuración completada!"
echo " Ejecuta 'flutter run' para compilar."
echo "======================================"
