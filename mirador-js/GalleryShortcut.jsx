import { useCallback } from 'react';
import { useTranslation } from 'mirador';
import { MiradorMenuButton } from 'mirador';
import GridOn from '@mui/icons-material/GridOn';

const GalleryShortcut = (props) => {
  const { t } = useTranslation();

  return (
    <MiradorMenuButton
      aria-label={t('gallery')}
      onClick={() => props.switchToGalleryView()}
    >
      <GridOn />
    </MiradorMenuButton>
  );
};

export default {
  target: 'WindowTopBarPluginArea',
  mode: 'add',
  name: 'GalleryShortcut',
  component: GalleryShortcut,
  mapDispatchToProps: (dispatch, { windowId }) => ({
    switchToGalleryView: () => dispatch({
        type: 'mirador/SET_WINDOW_VIEW_TYPE',
        viewType: 'gallery',
        windowId,
    }),
  }),
  mapStateToProps: (state, { windowId }) => ({
    windowId: windowId,
  }),
};
