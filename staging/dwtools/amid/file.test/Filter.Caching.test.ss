( function _Filter_Caching_test_ss_( ) {

'use strict';

// !!! disabled because it is experimental functionality
// return;
// console.warn( 'REMINDER : fix me' );
// !!!

if( typeof module !== 'undefined' )
{
  require( '../files/l8_filter/Caching.s' );

  var _ = _global_.wTools;

  _.include( 'wTesting' );

  // console.log( '_.fileProvider :',_.fileProvider );

}

//

var _ = _global_.wTools;
var Parent = _.Tester;
var testDirectory = __dirname + '/../../../../tmp.tmp/caching';

var provider = _.fileProvider;
var testData = 'data';

_.assert( !!Parent );

//

function fileWatcher( t )
{
  provider.filesDelete( testDirectory );
  provider.directoryMake( testDirectory );
  var filePath = _.path.resolve( _.path.join( testDirectory, 'file' ) );
  var dir = provider.pathNativize( testDirectory );

  //

  t.description = 'Caching.fileWatcher test';

  var caching = _.FileFilter.Caching({ watchPath : testDirectory });
  var onReady = caching.fileWatcher.onReady.split();
  var onUpdate = caching.fileWatcher.onUpdate;

  var dstPath = _.path.resolve( _.path.join( dir, 'dst' ) );

  function _cacheFile( filePath, clear )
  {
    if( clear )
    {
      caching._cacheStats = {};
      caching._cacheDir = {};
      caching._cacheRecord = {};
    }

    caching.fileStat( filePath );
    caching.directoryRead( filePath );
    caching.fileRecord( filePath, { fileProvider : provider } );
  }

  /* write file, file cached */

  onReady
  .got( function()
  {
    _cacheFile( filePath );
    provider.fileWrite( filePath, testData );
    onUpdate.got( function()
    {
      var got = caching._cacheStats[ filePath ];
      var expected = provider.fileStat( filePath );
      t.identical( [ got.dev, got.size, got.ino ], [ expected.dev, expected.size, expected.ino ] );
      var got = caching._cacheRecord[ filePath ][ 1 ].stat;
      t.identical( [ got.dev, got.size, got.ino ], [ expected.dev, expected.size, expected.ino ] );
      var got = caching._cacheDir[ filePath ];
      var expected = [ _.path.name( filePath ) ];
      t.identical( got, expected );
      onReady.give();
    })
  })

  /* write file, dir cached */

  .got( function()
  {
    _cacheFile( _.path.resolve( dir ), true );
    provider.fileWrite( filePath, testData );
    onUpdate.got( function()
    {
      var dir = _.path.resolve( _.path.dir( filePath ) );
      var got = caching._cacheStats[ dir ];
      var expected = provider.fileStat( dir );
      t.identical( [ got.dev, got.size, got.ino, got.isDirectory() ], [ expected.dev, expected.size, expected.ino,expected.isDirectory() ] );
      var got = caching._cacheRecord[ dir ][ 1 ].stat;
      t.identical( [ got.dev, got.size, got.ino, got.isDirectory() ], [ expected.dev, expected.size, expected.ino,expected.isDirectory() ] );
      var got = caching._cacheDir[ dir ];
      var expected = [ _.path.name( filePath ) ];
      t.identical( got, expected );
      onReady.give();
    })
  })

  /* delete file, file cached */

  .got( function()
  {
    _cacheFile( filePath, true );
    provider.fileDelete( filePath );
    onUpdate.got( function()
    {
      var got = caching._cacheStats[ filePath ];
      t.identical( got, null );
      var got = caching._cacheRecord[ filePath ][ 1 ];
      t.identical( got, null );
      var got = caching._cacheDir[ filePath ];
      var expected = null;
      t.identical( got, expected );
      onReady.give();
    })
  })

  /* write big file */

  .got( function()
  {
    _cacheFile( filePath, true );
    var data = _.strDup( testData, 8000000 );
    provider.fileWrite( filePath, data )
    onUpdate.got( function()
    {
      var got = caching._cacheStats[ filePath ];
      var expected = provider.fileStat( filePath );
      t.identical( [ got.dev, got.size, got.ino, got.isFile() ], [ expected.dev, expected.size, expected.ino,expected.isFile() ] );
      var got = caching._cacheRecord[ filePath ][ 1 ].stat;
      t.identical( [ got.dev, got.size, got.ino, got.isFile() ], [ expected.dev, expected.size, expected.ino,expected.isFile() ] );
      var got = caching._cacheDir[ filePath ];
      var expected = [ _.path.name( filePath ) ];
      t.identical( got, expected );
      onReady.give();
    })
  })

  /* copy file */

  .got( function()
  {
    _cacheFile( dstPath, true );
    provider.fileWrite( filePath, testData );
    onUpdate.got( function()
    {
      provider.fileCopy( dstPath, filePath );
    })
    onUpdate.got( function()
    {
      var got = caching._cacheStats[ dstPath ];
      var expected = provider.fileStat( dstPath );
      t.identical( [ got.dev, got.size, got.ino, got.isFile() ], [ expected.dev, expected.size, expected.ino,expected.isFile() ] );
      var got = caching._cacheRecord[ dstPath ][ 1 ].stat;
      t.identical( [ got.dev, got.size, got.ino, got.isFile() ], [ expected.dev, expected.size, expected.ino,expected.isFile() ] );
      var got = caching._cacheDir[ dstPath ];
      var expected = [ _.path.name( dstPath ) ];
      t.identical( got, expected );
      onReady.give();
    })
  })

  /* !!! onUpdate is not receiving any messages is call this case in sequence with others */

  .got( function()
  {
    _cacheFile( dstPath, true );

    provider.fileWrite( filePath, testData );

    /* After fileWrite call, no events emmited by chokidar, can be fixed if add delay.
    Problem appears if run this case in sequence with other cases
    */

    onUpdate = onUpdate.eitherThenSplit( _.timeOutError( 3000 ) );
    t.mustNotThrowError( onUpdate.split() );

    onUpdate.got( function( err )
    {
      if( err )
      return onReady.give();

      provider.fileCopy( dstPath, filePath );
    })
    onUpdate.got( function()
    {
      var got = caching._cacheStats[ dstPath ];
      var expected = provider.fileStat( dstPath );
      t.identical( [ got.dev, got.size, got.ino, got.isFile() ], [ expected.dev, expected.size, expected.ino,expected.isFile() ] );
      var got = caching._cacheRecord[ dstPath ][ 1 ].stat;
      t.identical( [ got.dev, got.size, got.ino, got.isFile() ], [ expected.dev, expected.size, expected.ino,expected.isFile() ] );
      var got = caching._cacheDir[ dstPath ];
      var expected = [ _.path.name( dstPath ) ];
      t.identical( got, expected );
      onReady.give();
    })
  })

  /* immediate writing and deleting of a file gives timeOutError becase no events emitted by chokidar */

  .got( function()
  {
    var newFile = _.path.resolve( _.path.join( dir, 'new' ) );
    _cacheFile( newFile, true );

    provider.fileWrite( newFile, testData );

    onUpdate = onUpdate.eitherThenSplit( _.timeOutError( 3000 ) );
    t.mustNotThrowError( onUpdate.split() );

    onUpdate.got( function( err, got )
    {
      if( err )
      return onReady.give();

      var got = caching._cacheStats[ newFile ];
      var expected = provider.fileStat( newFile );
      t.identical( [ got.dev, got.size, got.ino, got.isFile() ], [ expected.dev, expected.size, expected.ino,expected.isFile() ] );
      var got = caching._cacheRecord[ newFile ][ 1 ].stat;
      t.identical( [ got.dev, got.size, got.ino, got.isFile() ], [ expected.dev, expected.size, expected.ino,expected.isFile() ] );
      var got = caching._cacheDir[ dstPath ];
      var expected = [ _.path.name( dstPath ) ];
      t.identical( got, expected );
      onReady.give();
    })

  })

  return onReady;
}

fileWatcher.timeOut = 40000;


//

function fileWatcherOnReady( t )
{
  var filePath = _.path.resolve( _.path.join( testDirectory, 'file' ) );
  var dir = provider.pathNativize( _.path.dir( filePath ) );

  var caching = _.FileFilter.Caching({ watchPath : dir, watchOptions : { skipEvents : true } });
  var onReady = caching.fileWatcher.onReady.eitherThenSplit( _.timeOutError( 30000 ) );

  //

  t.description = 'Caching.fileWatcher onReady consequence test'

  /**/

  return t.shouldThrowErrorAsync( onReady );
}

fileWatcherOnReady.timeOut = 40000;

//

function fileWatcherOnUpdate( t )
{
  var filePath = _.path.resolve( _.path.join( testDirectory, 'file' ) );
  var dir = provider.pathNativize( _.path.dir( filePath ) );

  var caching = _.FileFilter.Caching({ watchPath : dir, watchOptions : {} });
  var onReady = caching.fileWatcher.onReady.split();
  var onUpdate = caching.fileWatcher.onUpdate.eitherThenSplit( _.timeOutError( 30000 ) );

  //

  t.description = 'Caching.fileWatcher onUpdate consequence test'

  /**/

  onReady.doThen( function( err, got )
  {
    t.identical( got, 'ready' );

    return t.shouldThrowErrorAsync( onUpdate );
  })

  return onReady;
}

fileWatcherOnUpdate.timeOut = 40000;

//

// --
// declare
// --

var Self =
{

  name : 'Tools/mid/files/filesFilter/Caching',
  silencing : 1,
  enabled : 0,

  tests :
  {
    fileWatcher : fileWatcher,
    fileWatcherOnReady : fileWatcherOnReady,
    fileWatcherOnUpdate : fileWatcherOnUpdate,
  },

}

Self = wTestSuite( Self )
if( typeof module !== 'undefined' && !module.parent )
_.Tester.test( Self.name );

} )( );
