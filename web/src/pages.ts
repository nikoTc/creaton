import HomePage from './pages/home.svelte';

type ComponentModule = {default: unknown};
export default [
  {
    name: 'Wallet',
    path: 'wallet',
    asyncComponent: (): Promise<ComponentModule> => import('./pages/wallet.svelte'),
  },
  {
    name: 'Home',
    path: '',
    component: HomePage, // Home Page is bundled for faster user interaction
  },
  {
    name: 'Sign up',
    path: 'creator-sign-up',
    asyncComponent: (): Promise<ComponentModule> => import('./pages/sign-up.svelte'),
  },
  {
    name: 'Creator',
    path: 'creator/:id',
    asyncComponent: (): Promise<ComponentModule> => import('./pages/creator.svelte'),
  },
  {
    name: 'CreatorUpload',
    path: 'creator-upload/:id',
    asyncComponent: (): Promise<ComponentModule> => import('./pages/upload.svelte'),
  },
  {
    name: 'NotFound',
    path: '.*',
    asyncComponent: (): Promise<ComponentModule> => import('./pages/notfound.svelte'),
  },
  {
    name: 'Creator Search',
    path: 'creator',
    asyncComponent: (): Promise<ComponentModule> => import('./pages/creatorsearch.svelte'),
  },
  {
    name: 'Creator Search Link',
    path: 'creator/*',
    asyncComponent: (): Promise<ComponentModule> => import('./pages/creatorsearch.svelte'),
  },
  {
    name: 'Upload',
    path: 'upload',
    asyncComponent: (): Promise<ComponentModule> => import('./pages/my-contracts.svelte'),
  },
];
