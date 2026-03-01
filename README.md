# Rifa Cannabis

Rifa premium: 100 números, sorteo **15 de marzo a las 15:00**. Premio: 10g cannabis (REPROCAN).  
1 número = **\$10.000** · 2 números = **\$15.000**. Hay ganador sí o sí.

## Configuración

### 1. Supabase

- Crear proyecto en [Supabase](https://supabase.com).
- En **SQL Editor** ejecutar el contenido de:
  `supabase/migrations/20250228000000_create_raffle_tickets.sql`
- En **Authentication → Providers** habilitar Email y definir un usuario admin (email + contraseña) para que solo ese usuario pueda asignar números.

### 2. Variables de entorno

- Copiar `.env.example` a `.env`.
- Completar con tu proyecto Supabase:

```env
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

Para **build Web** no uses `.env`; pasa las variables en el comando:

```bash
flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

### 3. Ejecutar

```bash
flutter pub get
flutter run
```

## Funcionalidad

- **Talonario**: 100 números a la izquierda. Al pasar el mouse sobre un número vendido se muestra el nombre del comprador.
- **Estadísticas**: Ranking de compradores por cantidad de números (más números = más chances). Gráfico de torta con detalle al tocar cada porción.
- **Cards**: Premio, precios, modalidad “hay ganador sí o sí”, contador regresivo hasta el 15/03 15:00.
- **Login**: Botón en esquina. Solo usuarios autenticados pueden entrar a **Administrar**.
- **Administrar**: Vista para asignar números (nombre + números separados por coma o espacio). El mismo nombre con más números suma chances.

## Seguridad (RLS)

- **SELECT** en `raffle_tickets`: público (talonario y estadísticas visibles para todos).
- **INSERT / UPDATE / DELETE**: solo usuarios autenticados (admin).
