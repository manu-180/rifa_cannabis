-- Ángulo donde debe parar la aguja (dentro del segmento, no siempre el centro).
ALTER TABLE public.raffle_draw
  ADD COLUMN IF NOT EXISTS needle_angle double precision;

COMMENT ON COLUMN public.raffle_draw.needle_angle IS 'Ángulo en grados (0=derecha) donde para la aguja; aleatorio dentro del segmento del ganador.';
