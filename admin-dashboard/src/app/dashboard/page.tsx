import { Grid } from '@mui/material';
import { PageHeader } from '@/components/ui/PageHeader';
import { PlaceholderCard } from '@/components/ui/PlaceholderCard';

export default function DashboardPage() {
  return (
    <>
      <PageHeader
        title="Dashboard Overview"
        description="Track high-level health signals of Edu Mate across content and community."
      />
      <Grid container spacing={2}>
        <Grid size={{ xs: 12, md: 6 }}>
          <PlaceholderCard
            title="Platform Snapshot"
            subtitle="Total users, active groups, and digital library activity will be surfaced here."
          />
        </Grid>
        <Grid size={{ xs: 12, md: 6 }}>
          <PlaceholderCard
            title="Moderation Queue"
            subtitle="Open reports and unresolved moderation tasks will appear in this area."
          />
        </Grid>
      </Grid>
    </>
  );
}
