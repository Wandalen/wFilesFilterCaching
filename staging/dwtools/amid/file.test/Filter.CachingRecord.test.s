( function _Filter_CachingRecord_test_ss_( ) {

'use strict';

// !!! disabled because is experimental
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
  var testDirectory = __dirname + '/../../../../tmp.tmp/cachingRecord';
  var provider = _.FileProvider.HardDrive();
}
else
{ var testTree = {};
  var provider = _.FileProvider.Extract({ filesTree : testTree });
  var testDirectory = '/tmp.tmp/cachingRecord';
}

//

var _ = _global_.wTools;
var Parent = _.Tester;
var o = { fileProvider : provider };
var cachingRecord = _.FileFilter.Caching({ original : provider, cachingDirs : 0, cachingStats : 0 });
_.assert( !!Parent );

//

function fileRead( t )
{
  if( !cachingRecord )
  cachingRecord = _.FileFilter.Caching({ original : provider, cachingDirs : 0, cachingStats : 0 });

  var filePath = _.path.join( testDirectory,'file' );
  var testData = 'Lorem ipsum dolor sit amet';

  //

  t.description = 'updateOnRead disabled '

  /**/

  provider.fileDelete( testDirectory );
  provider.fileWrite( filePath, testData );
  cachingRecord.fileRead( filePath );
  t.identical( cachingRecord._cacheRecord, {} );

  /* previously cached record*/

  provider.fileDelete( testDirectory );
  provider.fileWrite( filePath, testData );
  var expected = cachingRecord.fileRecord( filePath, o );
  cachingRecord.fileRead( filePath );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, expected );

  /* previously cached record, file not exist */

  cachingRecord._cacheRecord = {};
  provider.fileDelete( testDirectory );
  cachingRecord.fileRecord( filePath, o );
  t.shouldThrowErrorSync( function()
  {
    cachingRecord.fileRead( filePath );
  })
  got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got.stat, null );

  //

  t.description = 'updateOnRead enabled'
  var cachingRecord = _.FileFilter.Caching({ original : provider, cachingDirs : 0, cachingStats: 0, updateOnRead : 1 });

  /* cache is clean, nothing to update */

  provider.fileDelete( testDirectory );
  provider.fileWrite( filePath, testData );
  cachingRecord.fileRead( filePath );
  t.identical( cachingRecord._cacheRecord, {} )

  /* previously cached record */

  provider.fileDelete( testDirectory );
  cachingRecord.fileRecord( filePath, o );
  provider.fileWrite( filePath, testData );
  cachingRecord.fileRead( filePath );
  expected = provider.fileStat( filePath );
  got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ].stat;
  t.identical( _.objectIs( got ), true );
  t.identical( [ got.dev, got.size, got.ino ], [ expected.dev, expected.size, expected.ino ] );

  /* several previously cached records */

  provider.fileDelete( testDirectory );
  cachingRecord.fileRecord( filePath, o );
  var recordOptions1 = _.FileRecordContext( o, { relative : '/X' } );
  cachingRecord.fileRecord( filePath, recordOptions1 );
  var recordOptions2 = _.FileRecordContext( o, { dir : '/a', relative : '/x'  } );
  cachingRecord.fileRecord( filePath, recordOptions2 );
  provider.fileWrite( filePath, testData );
  cachingRecord.fileRead( filePath );
  expected = provider.fileStat( filePath );
  got = cachingRecord.fileRecord( filePath, o );
  t.identical( _.objectIs( got ), true );
  t.identical( [ got.stat.dev, got.stat.size, got.stat.ino ], [ expected.dev, expected.size, expected.ino ] );
  got = cachingRecord.fileRecord( filePath, recordOptions1 );
  t.identical( [ got.stat.dev, got.stat.size, got.stat.ino ], [ expected.dev, expected.size, expected.ino ] );
  got = cachingRecord.fileRecord( filePath, recordOptions2 );
  t.identical( [ got.stat.dev, got.stat.size, got.stat.ino ], [ expected.dev, expected.size, expected.ino ] );

  /* previously cached record, file not exist */

  cachingRecord._cacheRecord = {};
  provider.fileDelete( testDirectory );
  cachingRecord.fileRecord( filePath, o );
  t.shouldThrowErrorSync( function()
  {
    cachingRecord.fileRead( filePath );
  })
  got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got.stat, null );

  /* record cached, file was removed before read */

  cachingRecord._cacheRecord = {};
  provider.fileWrite( filePath, testData );
  cachingRecord.fileRecord( filePath, o );
  provider.fileDelete( filePath )
  t.shouldThrowErrorSync( function()
  {
    cachingRecord.fileRead( filePath );
  })
  var expected = null;
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got.stat, expected );

  cachingRecord.updateOnRead = false;
}

//

function fileWrite( t )
{
  var filePath = _.path.join( testDirectory,'file' );
  var testData = 'Lorem ipsum dolor sit amet';

  //

  t.description = 'fileWrite updates stat cache';

  /* file not exist in cache */

  provider.fileDelete( testDirectory );
  cachingRecord.fileWrite( filePath, testData );
  var dir = _.path.resolve( _.path.dir( filePath ) );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );

  /* file exist in cache */

  provider.fileDelete( testDirectory );
  cachingRecord.fileRecord( filePath, o );
  cachingRecord.fileWrite( filePath, testData );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( _.objectIs( got.stat ), true );
  t.identical( got.stat.isFile(), true );

  /* rewriting existing file, updates stats of cached record */

  cachingRecord._cacheRecord = {};
  provider.fileDelete( testDirectory );
  cachingRecord.fileWrite( filePath, testData );
  cachingRecord.fileRecord( filePath, o );
  //rewriting
  cachingRecord.fileWrite( filePath, testData + testData );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  var expected = provider.fileStat( filePath );
  t.identical( got.stat.size, expected.size )

  /* purging file before write */

  cachingRecord._cacheRecord = {};
  provider.fileDelete( testDirectory );
  cachingRecord.fileWrite( filePath, testData );
  cachingRecord.fileRecord( filePath, o );
  cachingRecord.fileWrite({ filePath : filePath, purging : 1, data : testData });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  var expected = provider.fileStat( filePath );
  t.identical([ got.stat.dev, got.stat.ino,got.stat.size ], [ expected.dev, expected.ino, expected.size ] );
}

//

function fileDelete( t )
{
  var filePath = _.path.join( testDirectory,'file' );
  var testData = 'Lorem ipsum dolor sit amet';

  //

  t.description = 'file deleting updates existing stat cache';
  cachingRecord._cacheRecord = {};
  var dir = _.path.dir( filePath );

  /* file record is not cached */

  provider.fileWrite( filePath, testData );
  cachingRecord.fileDelete( filePath );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );

  /* file record cached before delete */

  provider.fileWrite( filePath, testData );
  cachingRecord.fileRecord( filePath, o );
  cachingRecord.fileDelete( filePath );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, null );

  /* deleting empty folder, record cached */

  cachingRecord._cacheRecord = {};
  provider.fileDelete( dir );
  provider.directoryMake( dir  );
  cachingRecord.fileRecord( dir, o );
  cachingRecord.fileDelete( dir );
  var got = cachingRecord._cacheRecord[ _.path.resolve( dir ) ][ 1 ];
  t.identical( got, null );

  /* deleting folder with file, record cached */

  cachingRecord._cacheRecord = {};
  provider.fileWrite( filePath, testData );
  cachingRecord.fileRecord( dir, o );
  cachingRecord.fileRecord( filePath, o );
  cachingRecord.fileDelete( dir );
  var got = cachingRecord._cacheRecord[ _.path.resolve( dir ) ][ 1 ];
  t.identical( got, null );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, null );
}

//

function directoryMake( t )
{
  var filePath = _.path.join( testDirectory,'file' );
  var testData = 'Lorem ipsum dolor sit amet';

  //

  t.description = 'dir creation updates existing stat cache';
  cachingRecord._cacheRecord = {};

  /* rewritingTerminal enabled */

  provider.fileDelete( testDirectory );
  cachingRecord.directoryMake( testDirectory );
  var got = cachingRecord._cacheRecord[ _.path.resolve( testDirectory ) ];
  t.identical( got, undefined );

  /* rewritingTerminal disabled */

  cachingRecord._cacheRecord = {};
  provider.fileDelete( testDirectory );
  cachingRecord.directoryMake({ filePath : testDirectory, rewritingTerminal : 0 });
  var got = cachingRecord._cacheRecord[ _.path.resolve( testDirectory ) ];
  t.identical( got, undefined );

  /* rewritingTerminal enabled, update of existing file cache */

  cachingRecord._cacheRecord = {};
  provider.fileDelete( testDirectory );
  provider.fileWrite( filePath, testData );
  cachingRecord.fileRecord( filePath, o );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got.stat.isFile(), true  );
  cachingRecord.directoryMake( filePath );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got.stat.isDirectory(), true );

  /* rewritingTerminal disable, file prevents dir creation */

  cachingRecord._cacheRecord = {};
  provider.fileDelete( testDirectory );
  provider.fileWrite( filePath, testData );
  var expected = cachingRecord.fileRecord( filePath, o );
  t.shouldThrowErrorSync( function()
  {
    cachingRecord.directoryMake({ filePath : filePath, rewritingTerminal : 0 });
  })
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, expected );

  /* force disabled  */

  cachingRecord._cacheRecord = {};
  provider.fileDelete( testDirectory );
  t.shouldThrowErrorSync( function()
  {
    cachingRecord.directoryMake({ filePath : filePath, force : 0 });
  })
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );

  /* force and rewritingTerminal disabled */

  cachingRecord._cacheRecord = {};
  provider.fileDelete( testDirectory );
  t.shouldThrowErrorSync( function()
  {
    cachingRecord.directoryMake({ filePath : filePath, force : 0, rewritingTerminal : 0 });
  })
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ];
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
    cachingRecord.fileRename
    ({
      srcPath : filePath,
      dstPath : ' ',
      sync : 1,
      rewriting : 1,
      throwing : 1,
    });
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );

  /* src not exist, no changes in cache */

  provider.fileDelete( testDirectory );
  var expected = cachingRecord.fileRecord( filePath, o );
  t.shouldThrowErrorSync( function()
  {
    cachingRecord.fileRename
    ({
      srcPath : filePath,
      dstPath : ' ',
      sync : 1,
      rewriting : 1,
      throwing : 1,
    });
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, expected );

  /**/

  provider.fileDelete( testDirectory );
  cachingRecord._cacheRecord = {};
  cachingRecord.fileRename
  ({
    srcPath : filePath,
    dstPath : ' ',
    sync : 1,
    rewriting : 1,
    throwing : 0,
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );

  /* src not exist, no changes in cache */

  provider.fileDelete( testDirectory );
  cachingRecord._cacheRecord = {};
  var expected = cachingRecord.fileRecord( filePath, o );
  t.mustNotThrowError( function()
  {
    cachingRecord.fileRename
    ({
      srcPath : filePath,
      dstPath : ' ',
      sync : 1,
      rewriting : 1,
      throwing : 0,
    });
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, expected );

  //

  t.description = 'rename in same directory';
  var dstPath = _.path.join( testDirectory,'_file' );

  /* dst not exist */

  provider.fileDelete( testDirectory );
  provider.fileWrite( filePath, testData );
  cachingRecord._cacheRecord = {};
  cachingRecord.fileRecord( filePath, o );
  cachingRecord.fileRename
  ({
    srcPath : filePath,
    dstPath : dstPath,
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, null );

  /* rewriting existing dst*/

  provider.fileDelete( testDirectory );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( dstPath, testData + testData );
  cachingRecord._cacheRecord = {};
  cachingRecord.fileRecord( filePath, o );
  cachingRecord.fileRecord( dstPath, o );
  cachingRecord.fileRename
  ({
    srcPath : filePath,
    dstPath : dstPath,
    rewriting : 1
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, null );
  var got = cachingRecord._cacheRecord[ _.path.resolve( dstPath ) ][ 1 ];
  t.identical( got, null );

  //

  t.description = 'rename dir';
  var dstPath = _.path.join( testDirectory,'_file' );

  /* dst not exist */

  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  cachingRecord._cacheRecord = {};
  cachingRecord.fileRecord( filePath, o );
  cachingRecord.fileRecord( _.path.resolve( testDirectory ), o );
  cachingRecord.fileRename
  ({
    srcPath : testDirectory,
    dstPath : testDirectory + '_',
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( testDirectory + '_' ) ];
  t.identical( got, undefined );
  var got = cachingRecord._cacheRecord[ _.path.resolve( testDirectory ) ][ 1 ];
  t.identical( got, null );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, null );


  /* dst is empty dir */

  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  provider.directoryMake( testDirectory + '_' );
  cachingRecord._cacheRecord = {};
  cachingRecord.fileRecord( filePath, o );
  cachingRecord.fileRecord( _.path.resolve( testDirectory ), o );
  cachingRecord.fileRecord( _.path.resolve( testDirectory + '_' ), o );
  cachingRecord.fileRename
  ({
    srcPath : testDirectory,
    dstPath : testDirectory + '_',
    rewriting : 1,
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( testDirectory + '_' ) ][ 1 ];
  t.identical( got, null );
  var got = cachingRecord._cacheRecord[ _.path.resolve( testDirectory ) ][ 1 ];
  t.identical( got, null );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, null );

  /* dst is dir with files */

  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( _.path.join( testDirectory + '_', 'file' ), testData );
  cachingRecord._cacheRecord = {};
  cachingRecord.fileRecord( filePath, o );
  cachingRecord.fileRecord( _.path.resolve( testDirectory ), o );
  cachingRecord.fileRecord( _.path.resolve( testDirectory + '_' ), o );
  cachingRecord.fileRecord( _.path.join( testDirectory + '_', 'file' ), o );
  cachingRecord.fileRename
  ({
    srcPath : testDirectory,
    dstPath : testDirectory + '_',
    rewriting : 1
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( testDirectory + '_' ) ][ 1 ];
  t.identical( got, null );
  var got = cachingRecord._cacheRecord[ _.path.resolve( testDirectory ) ][ 1 ];
  t.identical( got, null );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, null );

  /* dst is dir with files, rewriting off, error expected, src/dst must not be changed */

  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( _.path.join( testDirectory + '_', 'file' ), testData );
  cachingRecord._cacheRecord = {};
  var expected1 = cachingRecord.fileRecord( _.path.resolve( testDirectory ), o );
  var expected2 = cachingRecord.fileRecord( _.path.resolve( testDirectory + '_' ), o );
  t.shouldThrowErrorSync( function()
  {
    cachingRecord.fileRename
    ({
      srcPath : testDirectory,
      dstPath : testDirectory + '_',
    });
  })
  var got = cachingRecord._cacheRecord[ _.path.resolve( testDirectory ) ][ 1 ];
  t.identical( got, expected1 );
  var got = cachingRecord._cacheRecord[ _.path.resolve( testDirectory + '_' ) ][ 1 ];
  t.identical( got, expected2 );

  /* dst is dir with files, rewriting off, throwing off, src/dst must not be changed */

  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( _.path.join( testDirectory + '_', 'file' ), testData );
  cachingRecord._cacheRecord = {};
  var expected1 = cachingRecord.fileRecord( _.path.resolve( testDirectory ), o );
  var expected2 = cachingRecord.fileRecord( _.path.resolve( testDirectory + '_' ), o );
  t.mustNotThrowError( function()
  {
    cachingRecord.fileRename
    ({
      srcPath : testDirectory,
      dstPath : testDirectory + '_',
      throwing : 0
    });
  })
  var got = cachingRecord._cacheRecord[ _.path.resolve( testDirectory ) ][ 1 ];
  t.identical( got, expected1 );
  var got = cachingRecord._cacheRecord[ _.path.resolve( testDirectory + '_' ) ][ 1 ];
  t.identical( got, expected2 );

  /* dst exist, record of file from src dir is cached before rename, must be deleted  */

  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( _.path.join( testDirectory + '_', 'file' ), testData );
  cachingRecord._cacheRecord = {};
  cachingRecord.fileRecord( filePath, o );
  cachingRecord.fileRename
  ({
    srcPath : testDirectory,
    dstPath : testDirectory + '_',
    rewriting : 1
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, null );
}

//

function fileCopy( t )
{
  var filePath = _.path.join( testDirectory,'file' );
  var testData = 'Lorem ipsum dolor sit amet';
  provider.fileDelete( testDirectory );

  //

  t.description = 'src not exist';
  cachingRecord._cacheRecord = {};

  /**/

  t.shouldThrowErrorSync( function()
  {
    cachingRecord.fileCopy
    ({
      srcPath : filePath,
      dstPath : ' ',
      sync : 1,
      rewriting : 1,
      throwing : 1,
    });
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ];
  var expected = undefined;
  t.identical( got, expected );

  /**/

  var expected = cachingRecord.fileRecord( filePath, o )
  t.shouldThrowErrorSync( function()
  {
    cachingRecord.fileCopy
    ({
      srcPath : filePath,
      dstPath : ' ',
      sync : 1,
      rewriting : 1,
      throwing : 1,
    });
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, expected );

  /**/

  cachingRecord._cacheRecord = {};
  t.mustNotThrowError( function()
  {
    cachingRecord.fileCopy
    ({
      srcPath : filePath,
      dstPath : ' ',
      sync : 1,
      rewriting : 1,
      throwing : 0,
    });
  });
  t.identical( cachingRecord._cacheRecord, {} );

  /**/

  cachingRecord._cacheRecord = {};
  var expected = cachingRecord.fileRecord( filePath, o )
  t.mustNotThrowError( function()
  {
    cachingRecord.fileCopy
    ({
      srcPath : filePath,
      dstPath : ' ',
      sync : 1,
      rewriting : 1,
      throwing : 0,
    });
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, expected );
  var got = cachingRecord._cacheRecord[ _.path.resolve( ' ' ) ];
  t.identical( got, undefined );

  //

  t.description = 'dst not exist';
  var dstPath = _.path.join( testDirectory, 'dst' );

  /* file, updateOnRead disabled */

  cachingRecord._cacheRecord = {};
  provider.fileWrite( filePath, testData );
  var expected = cachingRecord.fileRecord( filePath, o )
  cachingRecord.fileCopy
  ({
    srcPath : filePath,
    dstPath : dstPath,
    sync : 1,
    rewriting : 1,
    throwing : 1,
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, expected );
  var got = cachingRecord._cacheRecord[ _.path.resolve( dstPath ) ];
  t.identical( got, undefined );

  /* file, updateOnRead enabled */

  cachingRecord._cacheRecord = {};
  provider.fileWrite( filePath, testData );
  cachingRecord.fileRecord( filePath, o );
  cachingRecord.updateOnRead = 1;
  cachingRecord.fileCopy
  ({
    srcPath : filePath,
    dstPath : dstPath,
    sync : 1,
    rewriting : 1,
    throwing : 1,
  });
  cachingRecord.updateOnRead = 0;
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  var expected = provider.fileStat( filePath );
  if( got.stat.atime )
  t.identical( got.stat.atime.getTime(), expected.atime.getTime() );
  var got = cachingRecord._cacheRecord[ _.path.resolve( dstPath ) ];
  t.identical( got, undefined );

  /* file, rewriting dst - terminal file  */

  cachingRecord._cacheRecord = {};
  var dstPath = _.path.join( testDirectory, 'dst' );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( dstPath, testData + testData );
  var expected = cachingRecord.fileRecord( filePath, o );
  cachingRecord.fileRecord( dstPath, o );
  cachingRecord.fileCopy
  ({
    srcPath : filePath,
    dstPath : dstPath,
    sync : 1,
    rewriting : 1,
    throwing : 1,
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, expected );
  var got = cachingRecord._cacheRecord[ _.path.resolve( dstPath ) ];
  t.identical( got, undefined );

  /* file, rewriting dst - terminal file, rewriting off  */

  cachingRecord._cacheRecord = {};
  var dstPath = _.path.join( testDirectory, 'dst' );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( dstPath, testData + testData );
  var expected1 = cachingRecord.fileRecord( filePath, o );
  var expected2 = cachingRecord.fileRecord( dstPath, o );
  t.shouldThrowErrorSync( function()
  {
    cachingRecord.fileCopy
    ({
      srcPath : filePath,
      dstPath : dstPath,
      sync : 1,
      rewriting : 0,
      throwing : 1,
    });
  })
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, expected1 );
  var got = cachingRecord._cacheRecord[ _.path.resolve( dstPath ) ][ 1 ];
  t.identical( got, expected2 );

  /* copy folder */

  cachingRecord._cacheRecord = {};
  dstPath = testDirectory + '_';
  var expected1 = cachingRecord.fileRecord( _.path.resolve( testDirectory ), o );
  var expected2 = cachingRecord.fileRecord( _.path.resolve( dstPath ), o );
  provider.fileWrite( filePath, testData );
  t.shouldThrowErrorSync( function()
  {
    cachingRecord.fileCopy
    ({
      srcPath : testDirectory,
      dstPath : dstPath,
      sync : 1,
      rewriting : 1,
      throwing : 1,
    });
  })
  var got = cachingRecord._cacheRecord[ _.path.resolve( testDirectory ) ][ 1 ];
  t.identical( got, expected1 );
  var got = cachingRecord._cacheRecord[ _.path.resolve( dstPath ) ][ 1 ];
  t.identical( got, expected2 );

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

  /**/

  provider.fileWrite( filePath, testData );
  provider.fileWrite( filePath2, testData + testData );
  var expected1 = cachingRecord.fileRecord( filePath, o );
  var expected2 = cachingRecord.fileRecord( filePath2, o );
  cachingRecord.fileExchange( filePath2, filePath );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got.stat.size, expected2.stat.size );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath2 ) ][ 1 ];
  t.identical( got.stat.size, expected1.stat.size );

  //

  t.description = 'swap content of two dirs';

  /**/

  cachingRecord._cacheRecord = {};
  provider.fileDelete( testDirectory );
  provider.fileWrite( filePath, testData );
  provider.fileWrite( filePath2, testData + testData );
  cachingRecord.fileRecord( filePath, o );
  cachingRecord.fileRecord( filePath2, o );
  var expected1 = cachingRecord.fileRecord( _.path.dir( filePath ), o );
  var expected2 = cachingRecord.fileRecord( _.path.dir( filePath2 ), o );
  cachingRecord.fileExchange( _.path.dir( filePath2 ), _.path.dir( filePath ) );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, null );
  var got = cachingRecord._cacheRecord[ _.path.resolve(  filePath2 ) ][ 1 ];
  t.identical( got, null );
  var got = cachingRecord._cacheRecord[ _.path.resolve( _.path.dir( filePath ) ) ][ 1 ];
  t.identical( [ got.stat.dev, got.stat.ino,got.stat.size ], [ expected2.stat.dev, expected2.stat.ino, expected2.stat.size ] );
  var got = cachingRecord._cacheRecord[ _.path.resolve( _.path.dir( filePath2 ) ) ][ 1 ];
  t.identical( [ got.stat.dev, got.stat.ino,got.stat.size ], [ expected1.stat.dev, expected1.stat.ino, expected1.stat.size ] );

  //

  t.description = 'src not exist';

  /* allowMissing off, throwing on */

  cachingRecord._cacheRecord = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  t.shouldThrowErrorSync( function()
  {
    cachingRecord.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 1,
      allowMissing : 0
    });
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath2 ) ];
  t.identical( got, undefined );

  /* allowMissing off, throwing off */

  cachingRecord._cacheRecord = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  t.mustNotThrowError( function()
  {
    cachingRecord.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 0,
      allowMissing : 0
    });
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ];
  t.identical( got, undefined );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath2 ) ];
  t.identical( got, undefined );

  /* allowMissing off, throwing on, src cached */

  cachingRecord._cacheRecord = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  var expected = cachingRecord.fileRecord( filePath, o );
  t.shouldThrowErrorSync( function()
  {
    cachingRecord.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 1,
      allowMissing : 0
    });
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, expected );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath2 ) ];
  t.identical( got, undefined );

  /* allowMissing on, throwing on */

  cachingRecord._cacheRecord = {};
  var filePath2 = _.path.join( testDirectory, 'file2' )
  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath2, testData + testData );
  cachingRecord.fileRecord( filePath, o );
  var expected = cachingRecord.fileRecord( filePath2, o );
  cachingRecord.fileExchange
  ({
    dstPath : filePath2,
    srcPath : filePath,
    throwing : 1,
    allowMissing : 1
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( [ got.stat.dev, got.stat.ino, got.stat.size ], [ expected.stat.dev, expected.stat.ino, expected.stat.size ] );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath2 ) ][ 1 ];
  t.identical( got, null );

  //

  t.description = 'dst not exist';
  var filePath2 = _.path.join( testDirectory, 'file2' );

  /**/

  cachingRecord._cacheRecord = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  var expected = cachingRecord.fileRecord( filePath, o );
  cachingRecord.fileRecord( filePath2, o );
  cachingRecord.fileExchange
  ({
    dstPath : filePath2,
    srcPath : filePath,
    throwing : 1,
    allowMissing : 1
  });
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, null );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath2 ) ][ 1 ];
  t.identical( [ got.stat.dev, got.stat.ino, got.stat.size ], [ expected.stat.dev, expected.stat.ino, expected.stat.size ] );

  /**/

  cachingRecord._cacheRecord = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  var expected1 = cachingRecord.fileRecord( filePath, o );
  var expected2 = cachingRecord.fileRecord( filePath2, o );
  t.shouldThrowErrorSync( function()
  {
    cachingRecord.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 1,
      allowMissing : 0
    });
  })
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, expected1 );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath2 ) ][ 1 ];
  t.identical( got, expected2 );

  /**/

  cachingRecord._cacheRecord = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  provider.fileWrite( filePath, testData );
  var expected1 = cachingRecord.fileRecord( filePath, o );
  var expected2 = cachingRecord.fileRecord( filePath2, o );
  t.mustNotThrowError( function()
  {
    cachingRecord.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 0,
      allowMissing : 0
    });
  })
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, expected1 );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath2 ) ][ 1 ];
  t.identical( got, expected2 );

  //

  t.description = 'src & dst not exist';
  var filePath2 = _.path.join( testDirectory, 'file2' );

  /**/

  cachingRecord._cacheRecord = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  t.mustNotThrowError( function()
  {
    cachingRecord.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 1,
      allowMissing : 1
    });
  })
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ];
  var expected = provider.fileStat( filePath );
  t.identical( got, undefined );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath2 ) ];
  t.identical( got, undefined );

  /**/

  cachingRecord._cacheRecord = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  var expected1 = cachingRecord.fileRecord( filePath, o );
  var expected2 = cachingRecord.fileRecord( filePath2, o );
  t.mustNotThrowError( function()
  {
    cachingRecord.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 1,
      allowMissing : 1
    });
  })
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ][ 1 ];
  t.identical( got, expected1 );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath2 ) ][ 1 ];
  t.identical( got, expected2 );



  /* throwing 0, allowMissing 1 */

  cachingRecord._cacheRecord = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  t.mustNotThrowError( function()
  {
    cachingRecord.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 0,
      allowMissing : 1
    });
  })
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ];
  var expected = provider.fileStat( filePath );
  t.identical( got, undefined );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath2 ) ];
  t.identical( got, undefined );

  /* throwing 1, allowMissing 0 */

  cachingRecord._cacheRecord = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  t.shouldThrowErrorSync( function()
  {
    cachingRecord.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 1,
      allowMissing : 0
    });
  })
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ];
  var expected = provider.fileStat( filePath );
  t.identical( got, undefined );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath2 ) ];
  t.identical( got, undefined );

  /* throwing 0, allowMissing 0 */

  cachingRecord._cacheRecord = {};
  provider.fileDelete( _.path.dir( testDirectory ) );
  t.mustNotThrowError( function()
  {
    cachingRecord.fileExchange
    ({
      dstPath : filePath2,
      srcPath : filePath,
      throwing : 0,
      allowMissing : 0
    });
  })
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath ) ];
  var expected = provider.fileStat( filePath );
  t.identical( got, undefined );
  var got = cachingRecord._cacheRecord[ _.path.resolve( filePath2 ) ];
  t.identical( got, undefined );

}

// --
// declare
// --

var Self =
{

  name : 'Tools/mid/files/filesFilter/CachingRecords',
  silencing : 1,
  enabled : 0, // !!!

  tests :
  {
    fileRead : fileRead,
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
