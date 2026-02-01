import type { LucideIcon } from 'lucide-react';
import { LayoutDashboard } from 'lucide-react';

export interface NavTab {
  id: string;
  label: string;
  path: string;
  icon?: LucideIcon;
  activePaths?: string[];
  hasMenu?: boolean;
}

export interface NavSection {
  id: string;
  name: string;
  path: string;
  icon: LucideIcon;
  tabs: NavTab[];
  description?: string;
}

export interface Level2Nav {
  sectionPath: string;
  tabs: NavTab[];
}

export interface Level3Nav {
  parentPath: string;
  tabs: NavTab[];
}

/** Minimal navigation: one section (Dashboard) for multi-app with layout. */
export const navigation: NavSection[] = [
  {
    id: 'dashboard',
    name: 'Dashboard',
    path: '/',
    icon: LayoutDashboard,
    tabs: [{ id: 'home', label: 'Home', path: '/', icon: LayoutDashboard }],
    description: 'App home',
  },
];

export const level2Navigation: Level2Nav[] = [{ sectionPath: '/', tabs: [{ id: 'home', label: 'Home', path: '/', icon: LayoutDashboard }] }];
export const level3Navigation: Level3Nav[] = [];
