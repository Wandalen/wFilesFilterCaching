
if( typeof module !== 'undefined' )
require( 'wfilesfiltercaching' )

var _ = wTools;

var cachingDirs = _.FileFilter.Caching();

var dir = _.join( _.dir( _.realMainFile() ), 'cachingDirsSample' );
_.fileProvider.fileDelete( dir );
var filePath = _.join( dir, 'file.txt' );

/* new file */

// _.fileProvider.fileWrite( filePath, 'abc' );
// var files = cachingDirs.directoryRead( _.dir( _.realMainFile() ) );
// var files = cachingDirs.directoryRead( filePath );
// console.log( cachingDirs._cacheDir );

/* delete */

// cachingDirs.fileWrite( filePath, 'abc' );
// cachingDirs.fileDelete( filePath );
// var files = cachingDirs.directoryRead( dir );
// console.log( files );

/* new dir */

// cachingDirs.directoryMake( filePath );
// var files = cachingDirs.directoryRead( dir );
// console.log( files );

/* rename */

// cachingDirs.fileWrite( filePath, 'abc' );
// cachingDirs.fileRename( _.join( dir, 'file.js' ), dir );
// console.log( cachingDirs._cacheDir );

/* copy */

cachingDirs.fileWrite( filePath, 'abc' );
cachingDirs.fileCopy( _.join( dir, 'file.js' ), filePath );
console.log( cachingDirs._cacheDir );
