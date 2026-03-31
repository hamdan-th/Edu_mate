import { PageHeader } from '@/components/ui/PageHeader';
import { PlaceholderCard } from '@/components/ui/PlaceholderCard';

export default function ReportsPage() {
  return (
    <>
      <PageHeader
        title="Reports & Moderation"
        description="Triage abusive content reports and resolve moderation incidents."
      />
      <PlaceholderCard
        title="Reports module foundation ready"
        subtitle="Report queue, details panel, and moderation workflows will follow in Phase 2."
      />
    </>
  );
}
