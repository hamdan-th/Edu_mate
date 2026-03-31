import { PageHeader } from '@/components/ui/PageHeader';
import { PlaceholderCard } from '@/components/ui/PlaceholderCard';

export default function UsersPage() {
  return (
    <>
      <PageHeader
        title="Users Management"
        description="Search, review, and manage student and educator accounts."
      />
      <PlaceholderCard
        title="Users module foundation ready"
        subtitle="Tables, filters, and user status controls will be implemented in Phase 2."
      />
    </>
  );
}
