import { Paper, Typography } from '@mui/material';

type PlaceholderCardProps = {
  title: string;
  subtitle: string;
};

export function PlaceholderCard({ title, subtitle }: PlaceholderCardProps) {
  return (
    <Paper
      variant="outlined"
      sx={{ p: 3, borderRadius: 2, backgroundColor: 'background.paper' }}
    >
      <Typography variant="h6" fontWeight={600}>
        {title}
      </Typography>
      <Typography variant="body2" color="text.secondary" mt={1}>
        {subtitle}
      </Typography>
    </Paper>
  );
}
