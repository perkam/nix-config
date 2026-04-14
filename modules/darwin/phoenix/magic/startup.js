
/* STARTUP LAYOUT */

setEventHandler ( 'windowDidOpen', magicStartupOpen );

/* HELPERS */

function magicStartupOpen ( window ) {

  if ( !window.isNormal () || !window.isMain () ) return;

  const name = window.app ().name ();

  if ( name === 'Spotify' ) {
    setFrame ( 'half-1', window );
  } else if ( name === 'Obsidian' ) {
    setFrame ( 'half-2', window );
  }

}
