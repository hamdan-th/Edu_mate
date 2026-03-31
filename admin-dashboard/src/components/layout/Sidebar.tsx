'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  Drawer,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
} from '@mui/material';
import { dashboardNavigation } from '@/lib/navigation';

const drawerWidth = 260;

export function Sidebar() {
  const pathname = usePathname();

  return (
    <Drawer
      variant="permanent"
      sx={{
        width: drawerWidth,
        flexShrink: 0,
        [`& .MuiDrawer-paper`]: {
          width: drawerWidth,
          boxSizing: 'border-box',
          borderRight: 1,
          borderColor: 'divider',
        },
      }}
    >
      <Toolbar />
      <List sx={{ px: 1.5, py: 2 }}>
        {dashboardNavigation.map((item) => {
          const isActive = pathname === item.path;

          return (
            <ListItemButton
              key={item.path}
              component={Link}
              href={item.path}
              selected={isActive}
              sx={{ borderRadius: 2, mb: 0.5 }}
            >
              <ListItemIcon sx={{ minWidth: 38 }}>
                <item.icon fontSize="small" />
              </ListItemIcon>
              <ListItemText primary={item.label} />
            </ListItemButton>
          );
        })}
      </List>
    </Drawer>
  );
}
