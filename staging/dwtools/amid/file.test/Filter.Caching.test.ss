( function _FileProvider_Caching_test_ss_( ) {

'use strict';

if( typeof module !== 'undefined' )
{
  require( '../file/filter/Caching.s' );

  var _ = wTools;

  _.include( 'wTesting' );

  // console.log( '_.fileProvider :',_.fileProvider );

}

//

var _ = wTools;
var Parent = wTools.Tester;
var testDirectory = _.dirTempMake( _.pathJoin( __dirname, '../..' ) );

var provider = _.fileProvider;
var testData = 'data';

//

function cleanTestDir()
{
  _.fileProvider.fileDelete( testDirectory );
}

_.assert( Parent );

//

function fileWatcher( t )
{
  var pathDir = provider.pathNativize( _.pathJoin( testDirectory, t.name ) );
  provider.fileDelete( pathDir );
  provider.directoryMake( pathDir );
  var filePath = _.pathResolve( _.pathJoin( pathDir, 'file' ) );
  var dstPath = _.pathResolve( _.pathJoin( pathDir, 'dst' ) );

  function _cacheFile( caching, filePath, clear )
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

  //

  t.description = 'Caching.fileWatcher test';

  var con = new wConsequence().give()

  /**/

  con
  .doThen( function()
  {
    var caching = _.FileFilter.Caching({ watchPath : testDirectory });
    var onReady = caching.fileWatcher.onReady.split();
    var onUpdate = caching.fileWatcher.onUpdate;

    /* write file, file cached */

    onReady.got( function()
    {
      _cacheFile( caching,filePath );

      provider.fileWrite( filePath, testData );

      onUpdate.got( function( err, info )
      {
        t.identical( info.event, 'add' );
        t.identical( info.path, filePath );

        var got = caching._cacheStats[ filePath ];
        var expected = provider.fileStat( filePath );
        t.identical( [ got.dev, got.size, got.ino ], [ expected.dev, expected.size, expected.ino ] );
        var got = caching._cacheRecord[ filePath ][ 1 ].stat;
        t.identical( [ got.dev, got.size, got.ino ], [ expected.dev, expected.size, expected.ino ] );
        var got = caching._cacheDir[ filePath ];
        var expected = [ _.pathName( filePath ) ];
        t.identical( got, expected );
        caching.fileWatcher.close();
        onReady.give();
      })
    });

    return onReady;
  })

  /**/

  .doThen( function()
  {
    provider.fileDelete( pathDir );
    provider.directoryMake( pathDir );

    /* write file, dir cached */

    var caching = _.FileFilter.Caching({ watchPath : testDirectory });
    var onReady = caching.fileWatcher.onReady.split();
    var onUpdate = caching.fileWatcher.onUpdate;

    onReady.got( function()
    {
      _cacheFile( caching, pathDir, true );

      provider.fileWrite( filePath, testData );
      onUpdate.got( function( err, got )
      {
        //!!! some problem here with stats of dir that holds file( filePath ) stats or that directory are not updated but was cached
        //!!! same with stats inside record
        var got = caching._cacheStats[ pathDir ];
        var expected = provider.fileStat( pathDir );
        t.identical( [ got.dev, got.size, got.ino, got.isDirectory() ], [ expected.dev, expected.size, expected.ino,expected.isDirectory() ] );
        var got = caching._cacheRecord[ pathDir ][ 1 ].stat;
        t.identical( [ got.dev, got.size, got.ino, got.isDirectory() ], [ expected.dev, expected.size, expected.ino,expected.isDirectory() ] );
        var got = caching._cacheDir[ pathDir ];
        var expected = [ _.pathName( filePath ) ];
        t.identical( got, expected );
        caching.fileWatcher.close();
        onReady.give();
      })
    });
    return onReady;
  })

  /**/

  .doThen( function()
  {
    provider.fileDelete( pathDir );
    provider.fileWrite( filePath, testData );

    /* delete file, file cached */

    var caching = _.FileFilter.Caching({ watchPath : testDirectory });
    var onReady = caching.fileWatcher.onReady.split();
    var onUpdate = caching.fileWatcher.onUpdate;

    onReady.got( function()
    {
      _cacheFile( caching, filePath, true );

      provider.fileDelete( filePath );
      onUpdate.got( function( err, got )
      {
        var got = caching._cacheStats[ filePath ];
        t.identical( got, null );
        var got = caching._cacheRecord[ filePath ][ 1 ];
        t.identical( got, null );
        var got = caching._cacheDir[ filePath ];
        var expected = null;
        t.identical( got, expected );
        caching.fileWatcher.close();
        onReady.give();
      })
    })
    return onReady;
  })

  /**/

  .doThen( function()
  {
    provider.fileDelete( pathDir );
    provider.directoryMake( pathDir );

    var caching = _.FileFilter.Caching({ watchPath : testDirectory });
    var onReady = caching.fileWatcher.onReady.split();
    var onUpdate = caching.fileWatcher.onUpdate;

    /* write big file */

    onReady.got( function()
    {
      _cacheFile( caching, filePath, true );

      var data = _.strDup( testData, 8000000 );
      provider.fileWrite( filePath, data );

      onUpdate.got( function()
      {
        var got = caching._cacheStats[ filePath ];
        var expected = provider.fileStat( filePath );
        t.identical( [ got.dev, got.size, got.ino, got.isFile() ], [ expected.dev, expected.size, expected.ino,expected.isFile() ] );
        var got = caching._cacheRecord[ filePath ][ 1 ].stat;
        t.identical( [ got.dev, got.size, got.ino, got.isFile() ], [ expected.dev, expected.size, expected.ino,expected.isFile() ] );
        var got = caching._cacheDir[ filePath ];
        var expected = [ _.pathName( filePath ) ];
        t.identical( got, expected );
        caching.fileWatcher.close();
        onReady.give();
      })
    })

    return onReady;
  })

  /**/

  .doThen( function()
  {
    provider.fileDelete( pathDir );
    provider.directoryMake( pathDir );

    var caching = _.FileFilter.Caching({ watchPath : testDirectory });
    var onReady = caching.fileWatcher.onReady.split();
    var onUpdate = caching.fileWatcher.onUpdate;

    /* copy file */

    onReady.got( function()
    {
      _cacheFile( caching, dstPath, true );

      provider.fileWrite( filePath, testData );

      onUpdate.got( ( err, got ) =>
      {
        t.identical( got.event, 'add' );
        t.identical( got.path, filePath );

        provider.fileCopy( dstPath, filePath );
      })

      onUpdate.got( function( ere, got )
      {
        t.identical( got.event, 'add' );
        t.identical( got.path, dstPath );

        var got = caching._cacheStats[ dstPath ];
        var expected = provider.fileStat( dstPath );
        t.identical( [ got.dev, got.size, got.ino, got.isFile() ], [ expected.dev, expected.size, expected.ino,expected.isFile() ] );
        var got = caching._cacheRecord[ dstPath ][ 1 ].stat;
        t.identical( [ got.dev, got.size, got.ino, got.isFile() ], [ expected.dev, expected.size, expected.ino,expected.isFile() ] );
        var got = caching._cacheDir[ dstPath ];
        var expected = [ _.pathName( dstPath ) ];
        t.identical( got, expected );
        caching.fileWatcher.close();
        onReady.give();
      })
    });

    return onReady;
  })

  /**/

  .doThen( function()
  {
    provider.fileDelete( pathDir );
    provider.directoryMake( pathDir );

    var caching = _.FileFilter.Caching({ watchPath : testDirectory });
    var onReady = caching.fileWatcher.onReady.split();
    var onUpdate = caching.fileWatcher.onUpdate;

     // /* !!! onUpdate is not receiving any messages is call this case in sequence with others */

    onReady.got( function()
    {

      //  /* After fileWrite call, no events emmited by chokidar, can be fixed if add delay.
      // Problem appears if run this case in sequence with other cases
      // */

      _cacheFile( caching, dstPath, true );

      provider.fileWrite( filePath, testData );

      onUpdate.got( ( err, got ) =>
      {
        t.identical( got.event, 'add' );
        t.identical( got.path, filePath );

        provider.fileCopy( dstPath, filePath );
      });

      onUpdate.got( ( err, got ) =>
      {
        t.identical( got.event, 'add' );
        t.identical( got.path, dstPath );

        var got = caching._cacheStats[ dstPath ];
        var expected = provider.fileStat( dstPath );
        t.identical( [ got.dev, got.size, got.ino, got.isFile() ], [ expected.dev, expected.size, expected.ino,expected.isFile() ] );
        var got = caching._cacheRecord[ dstPath ][ 1 ].stat;
        t.identical( [ got.dev, got.size, got.ino, got.isFile() ], [ expected.dev, expected.size, expected.ino,expected.isFile() ] );
        var got = caching._cacheDir[ dstPath ];
        var expected = [ _.pathName( dstPath ) ];
        t.identical( got, expected );
        caching.fileWatcher.close();
        onReady.give();
      });
    })

    return onReady;
  })

  .doThen( function()
  {
    provider.fileDelete( pathDir );
    provider.directoryMake( pathDir );

    /* immediate writing and deleting of a file gives timeOutError becase no events emitted by chokidar */

    var caching = _.FileFilter.Caching({ watchPath : testDirectory });
    var onReady = caching.fileWatcher.onReady.split();
    var onUpdate = caching.fileWatcher.onUpdate;

    onReady.got( function()
    {
      var newFile = _.pathResolve( _.pathJoin( pathDir, 'new' ) );
      _cacheFile( caching, newFile, true );

      provider.fileWrite( newFile, testData );
      provider.fileDelete( newFile );

      onUpdate = onUpdate.eitherThenSplit( _.timeOutError( 10000 ) );
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
        var got = caching._cacheDir[ newFile ];
        var expected = [ _.pathName( newFile ) ];
        t.identical( got, expected );
        caching.fileWatcher.close();
        onReady.give();
      })
    })
    return onReady;
  })

  return con;
}

fileWatcher.timeOut = 60000;

//

function fileWatcherOnReady( t )
{
  var filePath = _.pathResolve( _.pathJoin( testDirectory, 'file' ) );
  var pathDir = provider.pathNativize( _.pathDir( filePath ) );

  var con = new wConsequence().give()

  /**/

  .doThen( function()
  {
    var caching = _.FileFilter.Caching({ watchPath : testDirectory });
    var onReady = caching.fileWatcher.onReady;

    t.description = 'Caching.fileWatcher onReady consequence test'

    onReady.doThen( ( err, got ) =>
    {
      t.identical( got, 'ready' );
      t.identical( caching.fileWatcher._readyEmitted, true );
      t.shouldBe( !!caching.fileWatcher._watched[ pathDir ] );
    })
    return onReady;
  })

  /**/

  .doThen( function()
  {
    var caching = _.FileFilter.Caching({ watchPath : testDirectory, watchOptions : { skipReadyEvent : 1 } });
    var onReady = caching.fileWatcher.onReady.eitherThenSplit( _.timeOutError( 10000 ) )

    t.description = 'Caching.fileWatcher onReady consequence test'

    return t.shouldThrowError( onReady );
  })

  return con;
}

fileWatcherOnReady.timeOut = 40000;

//

function fileWatcherOnUpdate( t )
{
  var filePath = _.pathResolve( _.pathJoin( testDirectory, 'file' ) );
  var pathDir = provider.pathNativize( _.pathDir( filePath ) );

  var con = new wConsequence().give()

  /**/

  .doThen( function()
  {
    var caching = _.FileFilter.Caching({ watchPath : testDirectory });
    var onReady = caching.fileWatcher.onReady;
    var onUpdate = caching.fileWatcher.onUpdate.eitherThenSplit( _.timeOutError( 10000 ) );

    t.description = 'Caching.fileWatcher onUpdate consequence test'

    onReady.doThen( ( err, got ) =>
    {
      t.identical( got, 'ready' );
      t.identical( caching.fileWatcher._readyEmitted, true );
      t.shouldBe( !!caching.fileWatcher._watched[ pathDir ] );

      return t.shouldThrowError( onUpdate )
    })
    return onReady;
  });

  return con;
}

fileWatcherOnUpdate.timeOut = 40000;

//

// --
// proto
// --

var Self =
{

  name : 'Filter.Caching',
  silencing : 1,

  onSuiteEnd : cleanTestDir,

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
