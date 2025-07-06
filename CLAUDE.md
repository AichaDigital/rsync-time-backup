# CLAUDE.md

Este archivo proporciona instrucciones a Claude Code (claude.ai/code) para trabajar con código en este repositorio.

## Instrucciones de Comunicación

- **Idioma**: Responde siempre en español (España) 
- **Código**: Mantén todo el código, comandos, variables y documentación técnica en inglés
- **Comentarios**: Los comentarios en código pueden ser en español si es necesario para claridad

## Resumen del Proyecto

Este es un fork de rsync-time-backup que proporciona funcionalidad de backup estilo Time Machine usando rsync. El script principal crea backups incrementales con hard-links para ahorrar espacio, similar a Time Machine pero con compatibilidad multiplataforma.

## Arquitectura

- **Script Principal**: `rsync_tmbackup.sh` - El script de backup principal escrito en bash
- **Tests**: `tests/populate_dest.php` - Script PHP para testing de destinos de backup
- **Documentación**: `README.md` - Documentación completa de uso

## Características Implementadas

- **Estrategias de Expiración**: Usa la opción `--max_backups N` para limitar el número de backups (por defecto: 10)
- **Flags rsync Modificados**: Manejo personalizado de flags para entornos sin root
- **Poda de Backups**: Elimina automáticamente los backups más antiguos cuando se alcanza el límite
- **Soporte SSH**: Backup hacia/desde destinos remotos
- **Verificaciones de Seguridad**: Requiere archivo backup.marker en el destino
- **Capacidad de Reanudación**: Puede reanudar backups interrumpidos

## Memoria Persistente
- Usa SuperMemory AI MCP para recordar información entre sesiones
- Guarda contextos importantes automáticamente
- **Nota**: La memoria actual funciona solo dentro de cada sesión individual

## Comandos de Uso

### Basic Backup
```bash
./rsync_tmbackup.sh /source/path /destination/path
```

### With Exclusions
```bash
./rsync_tmbackup.sh /source/path /destination/path exclusions.txt
```

### SSH Backup
```bash
./rsync_tmbackup.sh -p 2222 /source/path user@host:/destination/path
```

### Maximum Backups
```bash
./rsync_tmbackup.sh -m 20 /source/path /destination/path
```

### Custom Expiration Strategy
```bash
./rsync_tmbackup.sh --strategy "1:1 30:7 365:30" /source/path /destination/path
```

## Configuration Options

- `--max_backups N`: Maximum number of backups to keep (default: 10)
- `--strategy`: Expiration strategy (default: "1:1 30:7 365:30")
- `--rsync-append-flags`: Add custom rsync flags (recommended over --rsync-set-flags)
- `--log-dir`: Custom log directory
- `--no-auto-expire`: Disable automatic old backup deletion
- `--sudo`: Enable sudo usage in script

## Safety Requirements

- Destination must contain a `backup.marker` file
- Create marker: `mkdir -p /dest && touch /dest/backup.marker`
- Script prevents multiple simultaneous backups to same destination

## Testing

- PHP script in `tests/populate_dest.php` available for testing
- No automated test suite - manual testing required

## Important Notes

- This fork modifies default rsync flags for non-root environments
- Uses `--rsync-append-flags` instead of `--rsync-set-flags` for better compatibility
- Pruning strategy prioritizes keeping recent backups over older ones
- Built-in file locking prevents concurrent backup operations