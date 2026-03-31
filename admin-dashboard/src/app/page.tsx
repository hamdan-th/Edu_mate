import Link from 'next/link';
import { Box, Button, Container, Paper, Stack, Typography } from '@mui/material';

export default function HomePage() {
  return (
    <Container maxWidth="md" sx={{ py: 8 }}>
      <Paper variant="outlined" sx={{ p: 5, borderRadius: 3 }}>
        <Stack spacing={2}>
          <Typography variant="h3" component="h1" fontWeight={700}>
            Admin Dashboard
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Welcome to Edu Mate administration portal. Use the dashboard to manage users, groups,
            library resources, and moderation workflows.
          </Typography>
          <Box>
            <Button component={Link} href="/dashboard" variant="contained" size="large">
              Go to Dashboard
            </Button>
          </Box>
        </Stack>
      </Paper>
    </Container>
  );
}
