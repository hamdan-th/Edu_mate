import { PageHeader } from '@/components/ui/PageHeader';
import { PlaceholderCard } from '@/components/ui/PlaceholderCard';

export default function LibraryPage() {
  return (
    <>
      <PageHeader
        title="Digital Library Management"
        description="Review and moderate educational files and library collections."
      />
      <PlaceholderCard
        title="Library module foundation ready"
        subtitle="Content lists, metadata management, and actions will be integrated in Phase 2."
      />
    </>
  );
}
