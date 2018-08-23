( function _Filter_CachingDir_test_s_( ) {

'use strict';

// !!! disabled because it is experimental functionality
// return;
// console.warn( 'REMINDER : fix me' );
// !!!

var isBrowser = true;
if( typeof module !== 'undefined' )
{
  isBrowser = false;
  require( '../files/l8_filter/Caching.s' );

  var _ = _global_.wTools;

  _.include( 'wTesting' );

  // console.log( 'provider :',provider );
}

var _ = _global_.wTools;

if( _.FileProvider.HardDrive )
{
  var testDirectory = __dirname + '/../../../../tmp.tmp/cachingDir';
  var provider = _.FileProvider.HardDrive();
}
else
{ var testTree = {};
  var provider = _.FileProvider.Extract({ filesTree : testTree });
  var testDirectory = 'tmp.tmp/cachingDir';
}

//

var Parent = _.Tester;

var cachingDirs = _.FileFilter.Caching({ original : provider, cachingStats : 0, cachingRecord : 0 });

_.assert( !!Parent );

//


function simple( t )
{
  t.description = 'CachingDir test';

  var filter = _.FileFilter.Caching({ original : provider, cachingStats : 0 });

  var path = _.path.refine( _.path.dir( _.diagnosticLocation().path ) );
  logger.log( 'path',path );

  var timeSingle = _.timeNow();
  provider.directoryRead( path );
  timeSingle = _.timeNow() - timeSingle;

  var time1 = _.timeNow();
  for( var i = 0; i < 10000; ++i )
  {
    provider.directoryRead( path );
  }
  logger.log( _.timeSpent( 'Spent to make provider.directoryRead 10k times',time1-timeSingle ) );

  var time2 = _.timeNow();
  for( var i = 0; i < 10000; ++i )
  {
    filter.directoryRead( path );
  }
  logger.log( _.timeSpent( 'Spent to make filter.directoryRead 10k times',time2-timeSingle ) );

  t.identical( 1, 1 )
}

//

function filesFind( t )
{
  t.description = 'CachingDir filesFind';

  var filter = _.FileFilter.Caching({ original : provider, cachingStats : 0 });

  var path = _.path.refine( _.path.dir( _.diagnosticLocation().path ) );
  logger.log( 'path',path );

  var timeSingle = _.timeNow();
  provider.filesFind({ filePath : path });
  timeSingle = _.timeNow() - timeSingle;

  var time1 = _.timeNow();
  for( var i = 0; i < 100; ++i )
  {
    provider.filesFind({ filePath : path });
  }
  logger.log( _.timeSpent( 'Spent to make provider.filesFind 100 times',time1-timeSingle ) );

  var time2 = _.timeNow();
  for( var i = 0; i < 100; ++i )
  {
    filter.filesFind({ filePath : path });
  }
  logger.log( _.timeSpent( 'Spent to make filter.filesFind 100 times',time2-timeSingle ) );

  t.identical( 1, 1 )
}

//

function directoryRead( t )
{

  var filter = _.FileFilter.Caching({ original : provider, cachingStats : 0, cachingRecord : 0 });
  var path = _.path.refine( _.diagnosticLocation().path );
  logger.log( 'path',path );

  var consequence = new _.Consequence().give();

  consequence

  //

  .ifNoErrorThen( function()
  {
    t.description = 'filter.directoryRead must work like original provider';
  })

  /* compare results sync*/

  .ifNoErrorThen( function()
  {
    var expected = provider.directoryRead( path );
    var got = filter.directoryRead( path );
    t.identical( got, expected );
  })

  /*compare results async*/

  .ifNoErrorThen( function()
  {
    var expected;
    provider.directoryRead({ filePath : path, sync : 0 })
    .ifNoErrorThen( function( got )
    {
      expected = got;
      filter.directoryRead({ filePath : path, sync : 0 })
      .ifNoErrorThen( function( got )
      {
        t.identical( got, expected );
      })
    });
  })

  /*path not exist in file system, default setting*/

  .ifNoErrorThen( function()
  {
    var expected = provider.directoryRead( 'invalid path' );
    var got = filter.directoryRead( 'invalid path' );
    t.identical( got, expected );
  })

  /*path not exist in file system, sync, throwing enabled*/

  .ifNoErrorThen( function()
  {
    filter._cacheDir = {}
    t.shouldThrowErrorSync( function()
    {
      filter.directoryRead({ filePath : 'invalid path', sync : 1, throwing : 1 });
    });
  })

  /*path not exist in file system, async, throwing disabled*/

  .ifNoErrorThen( function()
  {
    var expected;
    provider.directoryRead({ filePath : 'invalid path', sync : 0, throwing : 0 })
    .ifNoErrorThen( function( got )
    {
      expected  = got;
      filter.directoryRead({ filePath : 'invalid path', sync : 0, throwing : 0 })
      .ifNoErrorThen( function( got )
      {
        t.identical( got, expected );
      })
    });
  })

  /*path not exist in file system, async, throwing enabled*/

  .ifNoErrorThen( function()
  {
    var con = filter.directoryRead({ filePath : 'invalid path', sync : 0, throwing : 1 });
    return t.shouldThrowErrorAsync( con )
    .doThen( function()
    {
    })
  })


  return consequence;
}


//

function fileWrite( t )
{
  var filePath = _.path.join( testDirectory,'file' );
  var testData = 'Lorem ipsum dolor sit amet';
  var dir = _.path.dir( filePath );

  //

  t.description = 'fileWrite updates dirs cache';

  /* file not exist in cache, dir creation in write process not affects on cache */

  provider.fileDelete( testDirectory );
  cachingDirs.fileWrite( filePath, testData );
  var dir = _.path.resolve( _.path.dir( filePath ) );
  var got = cachingDirs._cacheDir;
  t.identical( got, {} );

  /* dir cached, writing file into that dir updates cache */

  provider.fileDelete( testDirectory );
  provider.directoryMake( dir );
  cachingDirs.directoryRead( dir );
  cachingDirs.fileWrite( filePath, testData );
  var got = cachingDirs._cacheDir[ _.path.resolve( dir ) ];
  t.identical( got, [ 'file' ] );

  /* rewriting existing file, dir not cached */

  cachingDirs._cacheDir = {};
  provider.fileDelete( testDirectory );
  cachingDirs.fileWrite( filePath, testData );
  var got = cachingDirs._cacheDir[ _.path.resolve( dir ) ]
  var expected = undefined;
  t.identical( got, expected );
  //rewriting
  cachingDirs.fileWrite( filePath, testData + testData );
  var got = cachingDirs._cacheDir[ _.path.resolve( dir ) ];
  t.identical( got, expected );

  /* rewriting existing file, dir cached */

  cachingDirs._cacheDir = {};
  provider.fileDelete( testDirectory );
  cachingDirs.fileWrite( filePath, testData );
  var got = cachingDirs.directoryRead( dir );
  var expected = [ 'file' ];
  t.identical( got, expected );
  //rewriting
  cachingDirs.fileWrite( filePath, testData + testData );
  var got = cachingDirs._cacheDir[ _.path.resolve( dir ) ];
  t.identical( got, expected );

  /* purging file before write */

  cachingDirs._cacheDir = {};
  provider.fileDelete( testDirectory );
  cachingDirs.fileWrite( filePath, testData );
  var got = cachingDirs.directoryRead( dir );
  var expected = [ 'file' ];
  t.identical( got, expected );
  cachingDirs.fileWrite({ filePath : filePath, data :  testData + testData, purging : 1 });
  var got = cachingDirs._cacheDir[ _.path.resolve( dir ) ];
  t.identical( got, expected );
}

//

function fileDelete( t )
{
  var filePath = _.path.join( testDirectory,'file' );
  var testData = 'Lorem ipsum dolor sit amet';

  //

  t.description = 'file deleting updates existing stat cache';
  var dir = _.path.dir( filePath );

  /* file is not cached */
  cachingDirs._cacheDir = {};
  provider.directoryMake( dir );
  cachingDirs.fileDelete( filePath );
  var got = cachingDirs._cacheDir;
  t.identical( got, {});

  /* file cached befor delete */

  cachingDirs._cacheDir = {};
  provider.fileWrite( filePath, testData );
  cachingDirs.directoryRead( dir );
  cachingDirs.fileDelete( filePath );
  var got = cachingDirs.directoryRead( dir );
  t.identical( got, [] );

  /* delete empty folder */

  cachingDirs._cacheDir = {};
  provider.directoryMake( dir );
  cachingDirs.directoryRead( dir );
  cachingDirs.fileDelete( dir );
  var got = cachingDirs.directoryRead( dir );
  t.identical( got, null );

  /* deleting folder with file, stat cached */

  cachingDirs._cacheDir = {};
  provider.fileWrite( filePath, testData );
  cachingDirs.directoryRead( dir );
  cachingDirs.directoryRead( filePath );
  cachingDirs.fileDelete( dir );
  var got = cachingDirs.directoryRead( dir );
  t.identical( got, null );
  var got = cachingDirs.directoryRead( filePath );
  t.identical( got, null );
}

//

function directoryMake( t )
{
  var filePath = _.path.join( testDirectory,'file' );
  var testData = 'Lorem ipsum dolor sit amet';

  //

  t.description = 'dir creation updates existing stat cache';
  var dir = _.path.dir( filePath );

  /* defaults, dir not cached */
  cachingDirs._cacheDir = {};
  provider.fileDelete( testDirectory );
  cachingDirs.directoryMake( testDirectory );
  var got = cachingDirs._cacheDir[ _.path.resolve( testDirectory ) ];
  t.identical( got, undefined );

  /* defaults, dir cached */
  cachingDirs._cacheDir = {};
  provider.fileDelete( testDirectory );
  cachingDirs.directoryRead( testDirectory );
  cachingDirs.directoryMake( testDirectory );
  var got = cachingDirs._cacheDir[ _.path.resolve( testDirectory ) ];
  t.identical( got, [] );

  /* rewritingTerminal, terminal cached */

  cachingDirs._cacheDir = {};
  provider.fileDelete( testDirectory );
  provider.fileWrite( testDirectory, testData );
  cachingDirs.directoryRead( testDirectory );
  cachingDirs.directoryMake( testDirectory );
  var got = cachingDirs._cacheDir[ _.path.resolve( testDirectory ) ];
  t.identical( got, [] );

  /* rewritingTerminal disabled, terminal cached */

  cachingDirs._cacheDir = {};
  provider.fileDelete( testDirectory );
  provider.fileWrite( testDirectory, testData );
  cachingDirs.directoryRead( testDirectory );
  t.shouldThrowErrorSync( function()
  {
    cachingDirs.directoryMake({ filePath : testDirectory, rewritingTerminal : 0 });
  })
  var got = cachingDirs._cacheDir[ _.path.resolve( testDirectory ) ];
  t.identical( got, [ _.path.name( testDirectory )] );


  /* force disabled, rewritingTerminal check caches file stat */

  cachingDirs._cacheDir = {};
  provider.fileDelete( testDirectory );
  t.shouldThrowErrorSync( function()
  {
    cachingDirs.directoryMake({ filePath : filePath, force : 0 });
  })
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );

  /* force and rewritingTerminal disabled */

  cachingDirs._cacheDir = {};
  provider.fileDelete( testDirectory );
  t.shouldThrowErrorSync( function()
  {
    cachingDirs.directoryMake({ filePath : filePath, force : 0, rewritingTerminal : 0 });
  })
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );
}

//

function fileRename( t )
{
  var filePath = _.path.join( testDirectory,'file' );
  var testData = 'Lorem ipsum dolor sit amet';

  //

  t.description = 'src not exist';

  /**/

  provider.fileDelete( testDirectory );
  t.shouldThrowErrorSync( function()
  {
    cachingDirs.fileRename
    ({
      srcPath : filePath,
      dstPath : ' ',
      sync : 1,
      rewriting : 1,
      throwing : 1,
    });
  });
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );

  /**/

  provider.fileDelete( testDirectory );
  cachingDirs._cacheDir = {};
  cachingDirs.fileRename
  ({
    srcPath : filePath,
    dstPath : ' ',
    sync : 1,
    rewriting : 1,
    throwing : 0,
  });
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );

  //

  t.description = 'rename in same directory';
  var dstPath = _.path.join( testDirectory,'_file' );

  /* dst not exist */

  provider.fileDelete( testDirectory );
  provider.fileWrite( filePath, testData );
  cachingDirs._cacheDir = {};
  cachingDirs.directoryRead( filePath );
  cachingDirs.directoryRead( _.path.dir( filePath  ) );
  cachingDirs.fileRename
  ({
    srcPath : filePath,
    dstPath : dstPath,
  });
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, null );
  var got = cachingDirs._cacheDir[ _.path.resolve( dstPath ) ];
  var expected = provider.directoryRead( dstPath );
  t.identical( got, expected );
  var got = cachingDirs._cacheDir[ _.path.resolve( _.path.dir( filePath ) ) ];
  var expected = provider.directoryRead( _.path.dir( filePath ) );
  t.identical( got, expected );

  /* rewriting existing dst*/

  provider.fileDelete( testDirectory );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( dstPath, testData + testData );
  cachingDirs._cacheDir = {};
  cachingDirs.directoryRead( filePath );
  cachingDirs.directoryRead( _.path.dir( filePath  ) );
  cachingDirs.fileRename
  ({
    srcPath : filePath,
    dstPath : dstPath,
    rewriting : 1
  });
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, null );
  var got = cachingDirs._cacheDir[ _.path.resolve( dstPath ) ];
  var expected = provider.directoryRead( dstPath );
  t.identical( got, expected );
  var got = cachingDirs._cacheDir[ _.path.resolve( _.path.dir( filePath ) ) ];
  var expected = provider.directoryRead( _.path.dir( filePath ) );
  t.identical( got, expected );

  //

  t.description = 'rename dir';
  var dstPath = _.path.join( testDirectory,'_file' );

  /* dst not exist */

  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  cachingDirs._cacheDir = {};
  cachingDirs.directoryRead( filePath );
  cachingDirs.directoryRead( testDirectory );
  cachingDirs.directoryRead( testDirectory + '_' );
  cachingDirs.fileRename
  ({
    srcPath : testDirectory,
    dstPath : testDirectory + '_',
  });
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, null );
  var got = cachingDirs._cacheDir[ _.path.resolve( testDirectory ) ];
  t.identical( got, null );
  var got = cachingDirs._cacheDir[ _.path.resolve( testDirectory + '_' ) ];
  var expected = provider.directoryRead( testDirectory + '_' );
  t.identical( got, expected );

  /* dst is empty dir */

  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  provider.directoryMake( testDirectory + '_' );
  cachingDirs._cacheDir = {};
  cachingDirs.directoryRead( filePath );
  cachingDirs.directoryRead( testDirectory );
  cachingDirs.directoryRead( testDirectory + '_' );
  cachingDirs.fileRename
  ({
    srcPath : testDirectory,
    dstPath : testDirectory + '_',
    rewriting : 1,
  });
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, null );
  var got = cachingDirs._cacheDir[ _.path.resolve( testDirectory ) ];
  t.identical( got, null );
  var got = cachingDirs._cacheDir[ _.path.resolve( testDirectory + '_' ) ];
  var expected = provider.directoryRead( testDirectory + '_' );
  t.identical( got, expected );

  /* dst is dir with files */

  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( _.path.join( testDirectory + '_', 'file' ), testData );
  cachingDirs._cacheDir = {};
  cachingDirs.directoryRead( filePath );
  cachingDirs.directoryRead( _.path.join( testDirectory + '_', 'file' ) );
  cachingDirs.directoryRead( testDirectory );
  cachingDirs.directoryRead( testDirectory + '_' );
  cachingDirs.fileRename
  ({
    srcPath : testDirectory,
    dstPath : testDirectory + '_',
    rewriting : 1
  });
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, null );
  var got = cachingDirs._cacheDir[ _.path.resolve( testDirectory ) ];
  t.identical( got, null );
  var got = cachingDirs._cacheDir[ _.path.resolve( testDirectory + '_' ) ];
  var expected = provider.directoryRead( testDirectory + '_' );
  t.identical( got, expected );
  var got = cachingDirs._cacheDir[ _.path.resolve( _.path.join( testDirectory + '_', 'file' ) ) ];
  t.identical( got, null );

  /* dst is dir with files, rewriting off, error expected, src/dst must not be changed */

  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( _.path.join( testDirectory + '_', 'file' ), testData );
  cachingDirs._cacheDir = {};
  var expected1 = cachingDirs.directoryRead( testDirectory );
  var expected2 = cachingDirs.directoryRead( testDirectory + '_' );
  t.shouldThrowErrorSync( function()
  {
    cachingDirs.fileRename
    ({
      srcPath : testDirectory,
      dstPath : testDirectory + '_',
    });
  })
  var got1 = cachingDirs._cacheDir[ _.path.resolve( testDirectory ) ];
  var got2 = cachingDirs._cacheDir[ _.path.resolve( testDirectory + '_' ) ];
  t.identical( got1, expected1 );
  t.identical( got2, expected2 );

  /* dst is dir with files, rewriting off, throwing off, src/dst must not be changed */

  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( _.path.join( testDirectory + '_', 'file' ), testData );
  cachingDirs._cacheDir = {};
  var expected1 = cachingDirs.directoryRead( testDirectory );
  var expected2 = cachingDirs.directoryRead( testDirectory + '_' );
  t.shouldThrowErrorSync( function()
  {
    cachingDirs.fileRename
    ({
      srcPath : testDirectory,
      dstPath : testDirectory + '_',
      rewriting : 0
    });
  })
  var got1 = cachingDirs._cacheDir[ _.path.resolve( testDirectory ) ];
  var got2 = cachingDirs._cacheDir[ _.path.resolve( testDirectory + '_' ) ];
  t.identical( got1, expected1 );
  t.identical( got2, expected2 );

  /* dst exist, file from src dir is cached before rename, must be deleted  */

  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( _.path.join( testDirectory + '_', 'file' ), testData );
  cachingDirs._cacheDir = {};
  cachingDirs.directoryRead( filePath );
  cachingDirs.fileRename
  ({
    srcPath : testDirectory,
    dstPath : testDirectory + '_',
    rewriting : 1
  });
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, null );
  var got = cachingDirs._cacheDir[ _.path.resolve( testDirectory + '_' ) ];
  t.identical( got, undefined );
}

//

function fileCopy( t )
{
  var filePath = _.path.join( testDirectory,'file' );
  var testData = 'Lorem ipsum dolor sit amet';
  provider.fileDelete( testDirectory );

  //

  t.description = 'src not exist';

  /**/

  t.shouldThrowErrorSync( function()
  {
    cachingDirs.fileCopy
    ({
      srcPath : filePath,
      dstPath : ' ',
      sync : 1,
      rewriting : 1,
      throwing : 1,
    });
  });
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  var expected = null;
  t.identical( got, expected );

  /**/

  cachingDirs._cacheDir = {};
  t.mustNotThrowError( function()
  {
    cachingDirs.fileCopy
    ({
      srcPath : filePath,
      dstPath : ' ',
      sync : 1,
      rewriting : 1,
      throwing : 0,
    });
  });
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  var expected = undefined;
  t.identical( got, expected );

  //

  t.description = 'dst not exist';
  var dstPath = _.path.join( testDirectory, 'dst' );

  /* file */

  cachingDirs._cacheDir = {};
  provider.fileWrite( filePath, testData );
  cachingDirs.directoryRead( filePath );
  cachingDirs.directoryRead( dstPath );
  cachingDirs.fileCopy
  ({
    srcPath : filePath,
    dstPath : dstPath,
    sync : 1,
    rewriting : 1,
    throwing : 1,
  });
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  var expected = provider.directoryRead( filePath );
  t.identical( got, expected );
  var got = cachingDirs._cacheDir[ _.path.resolve( dstPath ) ];
  var expected = provider.directoryRead( dstPath );
  t.identical( got, expected );

  /* file, rewriting dst - terminal file  */

  cachingDirs._cacheDir = {};
  var dstPath = _.path.join( testDirectory, 'dst' );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( dstPath, testData + testData );
  cachingDirs.directoryRead( filePath );
  cachingDirs.directoryRead( dstPath );
  cachingDirs.fileCopy
  ({
    srcPath : filePath,
    dstPath : dstPath,
    sync : 1,
    rewriting : 1,
    throwing : 1,
  });
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  var expected = provider.directoryRead( filePath );
  t.identical( got, expected );
  var got = cachingDirs._cacheDir[ _.path.resolve( dstPath ) ];
  var expected = provider.directoryRead( dstPath );
  t.identical( got, expected );

  /* file, rewriting dst - terminal file, rewriting off  */

  cachingDirs._cacheDir = {};
  var dstPath = _.path.join( testDirectory, 'dst' );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( dstPath, testData + testData );
  cachingDirs.directoryRead( filePath );
  cachingDirs.directoryRead( dstPath );
  t.shouldThrowErrorSync( function()
  {
    cachingDirs.fileCopy
    ({
      srcPath : filePath,
      dstPath : dstPath,
      sync : 1,
      rewriting : 0,
      throwing : 1,
    });
  })
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  var expected = provider.directoryRead( filePath );
  t.identical( got, expected );
  var got = cachingDirs._cacheDir[ _.path.resolve( dstPath ) ];
  var expected = provider.directoryRead( dstPath );
  t.identical( got, expected );

  /* copy folders */

  cachingDirs._cacheDir = {};
  dstPath = testDirectory + '_';
  provider.fileWrite( filePath, testData );
  cachingDirs.directoryRead( filePath );
  cachingDirs.directoryRead( dstPath );
  cachingDirs.directoryRead( testDirectory );
  t.shouldThrowErrorSync( function()
  {
    cachingDirs.fileCopy
    ({
      srcPath : testDirectory,
      dstPath : dstPath,
      sync : 1,
      rewriting : 1,
      throwing : 1,
    });
  })
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  var expected = provider.directoryRead( filePath );
  t.identical( got, expected );
  var got = cachingDirs._cacheDir[ _.path.resolve( testDirectory ) ];
  var expected = provider.directoryRead( testDirectory );
  t.identical( got, expected );
  var got = cachingDirs._cacheDir[ _.path.resolve( dstPath ) ];
  var expected = provider.directoryRead( dstPath );
  t.identical( got, expected );

}

//

function fileExchange( t )
{
  var filePath = _.path.join( testDirectory,'file' );
  var filePath2 = _.path.join( testDirectory + '_','file2' );
  var testData = 'Lorem ipsum dolor sit amet';
  provider.fileDelete( testDirectory );

  //

  t.description = 'swap two files content';

  /* not cached */
  cachingDirs._cacheDir = {};
  provider.fileWrite( filePath, testData );
  provider.fileWrite( filePath2, testData + testData );
  cachingDirs.fileExchange( filePath2, filePath );
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath2 ) ];
  t.identical( got, undefined );

  /* cached */

  provider.fileWrite( filePath, testData );
  provider.fileWrite( filePath2, testData + testData );
  var expected1 = cachingDirs.directoryRead( filePath );
  var expected2 = cachingDirs.directoryRead( filePath2 );
  cachingDirs.fileExchange( filePath2, filePath );
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, expected1 );
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath2 ) ];
  t.identical( got, expected2 );

  //

  t.description = 'swap content of two dirs';

  /**/

  cachingDirs._cacheDir = {};
  provider.fileDelete( testDirectory );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( filePath2, testData + testData );
  var expected1 = cachingDirs.directoryRead( _.path.dir( filePath ) );
  var expected2 = cachingDirs.directoryRead( _.path.dir( filePath2 ) );
  cachingDirs.fileExchange( _.path.dir( filePath2 ), _.path.dir( filePath ) );
  var got = cachingDirs._cacheDir[ _.path.resolve( _.path.dir( filePath ) ) ];
  t.identical( got, expected2 );
  var got = cachingDirs._cacheDir[ _.path.resolve( _.path.dir( filePath2 ) ) ];
  t.identical( got, expected1 );

  /* files from dirs are cached before exchange */

  cachingDirs._cacheDir = {};
  provider.fileDelete( testDirectory );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( filePath2, testData + testData );
  var expected1 = cachingDirs.directoryRead( _.path.dir( filePath ) );
  var expected2 = cachingDirs.directoryRead( _.path.dir( filePath2 ) );
  cachingDirs.directoryRead( filePath );
  cachingDirs.directoryRead( filePath2 );
  cachingDirs.fileExchange( _.path.dir( filePath2 ), _.path.dir( filePath ) );
  var got = cachingDirs._cacheDir[ _.path.resolve( _.path.dir( filePath ) ) ];
  t.identical( got, expected2 );
  var got = cachingDirs._cacheDir[ _.path.resolve( _.path.dir( filePath2 ) ) ];
  t.identical( got, expected1 );
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, null );
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath2 ) ];
  t.identical( got, null );

  //

  t.description = 'src not exist';

  /* allowMissing off, throwing on */

  cachingDirs._cacheDir = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  t.shouldThrowErrorSync( function()
  {
    cachingDirs.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 1,
      allowMissing : 0
    });
  });
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath2 ) ];
  t.identical( got, undefined );

  /* allowMissing off, throwing off */

  cachingDirs._cacheDir = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  t.mustNotThrowError( function()
  {
    cachingDirs.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 0,
      allowMissing : 0
    });
  });
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath2 ) ];
  t.identical( got, undefined );

  /* allowMissing on, throwing on */

  cachingDirs._cacheDir = {};
  var filePath2 = _.path.join( testDirectory, 'file2' )
  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath2, testData + testData );
  cachingDirs.directoryRead( filePath2 );
  cachingDirs.fileExchange
  ({
    dstPath : filePath2,
    srcPath : filePath,
    throwing : 1,
    allowMissing : 1
  });
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, [ _.path.name( filePath ) ] );
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath2 ) ];
  t.identical( got, null );

  //

  t.description = 'dst not exist';
  var filePath2 = _.path.join( testDirectory, 'file2' );

  /**/

  cachingDirs._cacheDir = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  cachingDirs.directoryRead( filePath );
  cachingDirs.fileExchange
  ({
    dstPath : filePath2,
    srcPath : filePath,
    throwing : 1,
    allowMissing : 1
  });
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, null );
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath2 ) ];
  t.identical( got, [ _.path.name( filePath2 ) ] );

  /**/

  cachingDirs._cacheDir = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  t.shouldThrowErrorSync( function()
  {
    cachingDirs.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 1,
      allowMissing : 0
    });
  })
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath2 ) ];
  t.identical( got, undefined );

  /**/

  cachingDirs._cacheDir = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  t.mustNotThrowError( function()
  {
    cachingDirs.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 0,
      allowMissing : 0
    });
  })
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath2 ) ];
  t.identical( got, undefined );

  //

  t.description = 'src & dst not exist';
  var filePath2 = _.path.join( testDirectory, 'file2' );

  /**/

  cachingDirs._cacheDir = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  t.mustNotThrowError( function()
  {
    cachingDirs.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 1,
      allowMissing : 1
    });
  })
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath2 ) ];
  t.identical( got, undefined );

  /* throwing 0, allowMissing 1 */

  cachingDirs._cacheDir = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  t.mustNotThrowError( function()
  {
    cachingDirs.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 0,
      allowMissing : 1
    });
  })
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath2 ) ];
  t.identical( got, undefined );

  /* throwing 1, allowMissing 0 */

  cachingDirs._cacheDir = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  t.shouldThrowErrorSync( function()
  {
    cachingDirs.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 1,
      allowMissing : 0
    });
  })
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath2 ) ];
  t.identical( got, undefined );

  /* throwing 0, allowMissing 0 */

  cachingDirs._cacheDir = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  t.mustNotThrowError( function()
  {
    cachingDirs.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 0,
      allowMissing : 0
    });
  })
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );
  var got = cachingDirs._cacheDir[ _.path.resolve( filePath2 ) ];
  t.identical( got, undefined );

}

// --
// declare
// --

var Self =
{

  name : 'Tools/mid/files/filesFilter/CachingDir',
  silencing : 1,
  enabled : 0, // !!!

  tests :
  {
    simple : simple,
    filesFind : filesFind,
    directoryRead : directoryRead,

    fileWrite : fileWrite,
    fileDelete : fileDelete,
    directoryMake : directoryMake,
    fileRename : fileRename,
    fileCopy : fileCopy,
    fileExchange : fileExchange,
  },

}

Self = wTestSuite( Self )
if( typeof module !== 'undefined' && !module.parent )
_.Tester.test( Self.name );

} )( );
