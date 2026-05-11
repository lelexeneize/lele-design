# Supabase Setup — Lele Design

## 1. Crear proyecto gratis

1. Andá a https://supabase.com y hacé clic en **Start your project**
2. Logeate con GitHub (o creá cuenta)
3. Creá un **new project**:
   - Nombre: `lele-design`
   - Database password: (elegí una segura, guardala)
   - Region: **South America** (o la más cercana)
   - Pricing: **Free**
4. Esperá a que termine de crear (~2 min)

## 2. Obtener credenciales

1. En el dashboard del proyecto, andá a **Project Settings → API**
2. Copiá estos dos valores:
   - **Project URL** (https://xxxxxxxxxxxx.supabase.co)
   - **anon public key**
3. Abrí `js/supabase-config.js` y reemplazá los valores vacíos

## 3. Crear tablas

1. En el dashboard, andá a **SQL Editor**
2. Hacé clic en **New query**
3. Copiá todo el contenido de `sql/schema.sql`
4. Ejecutalo (clic en **Run** o **Ctrl+Enter**)

## 4. Google Auth en Supabase (opcional, reemplaza el Google OAuth actual)

1. En el dashboard, andá a **Authentication → Providers**
2. Habilitá **Google**
3. En Google Cloud Console, agregá esta URL como Authorized redirect URI:
   `https://xxxxxxxxxxxx.supabase.co/auth/v1/callback`
4. Copiá el Client ID y Client Secret de Google a Supabase

## 5. Verificar

1. Abrí la web en Vercel
2. Registrate o logeate — los datos se guardan en Supabase
3. Probá la galería desde el admin — los works se sincronizan
4. Abrí en otro navegador — los datos persisten

---

**¿Problemas?** Si algo falla, la app sigue funcionando con localStorage como antes.
