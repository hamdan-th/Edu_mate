import { PageHeader } from '@/components/ui/PageHeader';
import { PlaceholderCard } from '@/components/ui/PlaceholderCard';

export default function GroupsPage() {
  return (
    <>
      <PageHeader
        title="Groups Management"
        description="Monitor group creation, membership, and group-level moderation status."
      />
      <PlaceholderCard
        title="Groups module foundation ready"
        subtitle="Group review tools and management actions will be added in the next phase."
      />
    </>
  );
}
