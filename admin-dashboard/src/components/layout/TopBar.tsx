import { AppBar, Box, Toolbar, Typography } from '@mui/material';

export function TopBar() {
  return (
    <AppBar
      position="sticky"
      color="inherit"
      elevation={0}
      sx={{ borderBottom: 1, borderColor: 'divider', zIndex: (theme) => theme.zIndex.drawer + 1 }}
    >
      <Toolbar>
        <Box>
          <Typography variant="h6" fontWeight={700}>
            Edu Mate Admin
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Moderation and platform management
          </Typography>
        </Box>
      </Toolbar>
    </AppBar>
  );
}
