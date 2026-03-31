import DashboardOutlinedIcon from '@mui/icons-material/DashboardOutlined';
import GroupOutlinedIcon from '@mui/icons-material/GroupOutlined';
import AutoStoriesOutlinedIcon from '@mui/icons-material/AutoStoriesOutlined';
import ReportProblemOutlinedIcon from '@mui/icons-material/ReportProblemOutlined';
import PeopleAltOutlinedIcon from '@mui/icons-material/PeopleAltOutlined';
import type { NavItem } from '@/types/navigation';

export const dashboardNavigation: NavItem[] = [
  { label: 'Overview', path: '/dashboard', icon: DashboardOutlinedIcon },
  { label: 'Users', path: '/dashboard/users', icon: PeopleAltOutlinedIcon },
  { label: 'Groups', path: '/dashboard/groups', icon: GroupOutlinedIcon },
  { label: 'Library', path: '/dashboard/library', icon: AutoStoriesOutlinedIcon },
  { label: 'Reports', path: '/dashboard/reports', icon: ReportProblemOutlinedIcon },
];
