import { Stack, Typography } from '@mui/material';

type PageHeaderProps = {
  title: string;
  description: string;
};

export function PageHeader({ title, description }: PageHeaderProps) {
  return (
    <Stack spacing={0.5} mb={3}>
      <Typography variant="h4" component="h1" fontWeight={700}>
        {title}
      </Typography>
      <Typography variant="body1" color="text.secondary">
        {description}
      </Typography>
    </Stack>
  );
}
