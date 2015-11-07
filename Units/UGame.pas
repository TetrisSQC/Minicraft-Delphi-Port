{$I compiler.inc}
{.$DEFINE ANIMATEDABOUT }
unit UGame;

// Android: assets\internal\
// IOS: StartUp\Documents
// TODO: Fix memory leaks by using Interfaces instead of classes!
interface

{$IFDEF XE5}

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ENDIF}
  System.UIConsts, System.SyncObjs, System.Classes,
  System.Generics.Collections, System.Generics.Defaults,
  FMX.Graphics, FMX.Types, FMX.Media;
{$ELSE}
uses Classes, Windows, Graphics;
{$ENDIF}

const
  OPENED_FLAG = 1 shl 4;
  LOCKED_FLAG = 1 shl 5;
  HEALTH_MASK = OPENED_FLAG - 1;
  HEARING_DISTANCE = 2 * 8 * 16;
  MAX_FOG = 40;

  DAY_LENGTH = 20000;

type
  TByteArray = array of Byte;
  TGamePixelBuffer = array of Cardinal;

  TTile = class;
  TPlayer = class;
  TItemEntity = class;
  TEntity = class;
  TLivingEntity = class;
  TMob = class;
  TFurniture = class;
  TInventory = class;
  TScreen = class;
  TGame = class;
  TRecipe = class;
  TListItem = class;
  TResourceItem = class;

  TKey = class
  private
    FPresses: integer;
    FAbsorbs: integer;
    FDown: Boolean;
    FClicked: Boolean;
  public
    constructor create;

    procedure Toggle(const pressed: Boolean);
    procedure Tick;
    procedure Release;

    property Down: Boolean read FDown;
    property Clicked: Boolean read FClicked;
  end;

  TInputHandler = class
  public
    up, Down, left, right, attack, menu: TKey;

    constructor create;
    destructor Destroy; override;

    procedure ReleaseAll;

    procedure Tick;
    procedure Toggle(Key: Word; pressed: Boolean);
  end;

{$IFDEF XE5}

  TEntityList = TList<TEntity>;
  TRecipeList = TList<TRecipe>;
  TItemList = TList<TListItem>;
  TTileList = TList<TTile>;
  TResourceList = TList<TResourceItem>;
{$ELSE}
  TEntityList = TList;
  TRecipeList = TList;
  TItemList = TList;
  TTileList = TList;
  TResourceList = TList;
{$ENDIF}

  TLevel = class
  private
    map: TByteArray;
    data: TByteArray;

    entitiesInTiles: array of TEntityList;
    entities: TEntityList;

    depth: integer;
    dayFog: integer;

    procedure insertEntity(x, y: integer; e: TEntity);
    procedure removeEntity(x, y: integer; e: TEntity);
    procedure sortAndRender(screen: TScreen; List: TEntityList);
  public
    w, h: integer;
    monsterDensity: integer;
    player: TPlayer;
    grasscolor: Cardinal;
    dirtcolor: Cardinal;
    sandcolor: Cardinal;

    constructor create(const w, h, level: integer; parentLevel: TLevel);
    destructor Destroy; override;

    procedure renderBackground(screen: TScreen;
      const xScroll, yScroll: integer);
    procedure renderLight(screen: TScreen; xScroll, yScroll: integer);
    procedure renderSprites(screen: TScreen; const xScroll, yScroll: integer);
    procedure renderFog(screen, light: TScreen;
      const xScroll, yScroll: integer);

    procedure add(entity: TEntity);
    procedure remove(e: TEntity);

    procedure Tick();
    function getEntities(x0, y0, x1, y1: integer): TEntityList;

    function getTile(const x, y: integer): TTile;
    procedure setTile(const x, y: integer; const t: TTile;
      const dataVal: integer);
    function getData(const x, y: integer): integer;
    procedure setData(const x, y, val: integer);

    procedure trySpawn(const count: integer);
  end;

  TLevelGen = class
  private
    w, h: integer;
    values: array of single;

    procedure setSample(const x, y: integer; value: single);
    function sample(const x, y: integer): single;
  public
    constructor create(const w, h, featureSize: integer);

    destructor Destroy; override;
  end;

  TResource = class
    name: string;
    sprite: integer;
    color: Cardinal;
    constructor create(const name: string; const sprite: integer;
      const color: Cardinal);
    function interactOn(tile: TTile; level: TLevel; xt, yt: integer;
      player: TPlayer; attackDir: integer): Boolean; virtual;
  end;

  TResources = class
    res_wood: TResource;
    res_stone: TResource;
    res_flower: TResource;
    res_acorn: TResource;
    res_dirt: TResource;
    res_sand: TResource;
    res_cactusFlower: TResource;
    res_seeds: TResource;
    res_wheat: TResource;
    res_bread: TResource;
    res_apple: TResource;

    res_coal: TResource;
    res_ironOre: TResource;
    res_goldOre: TResource;
    res_ironIngot: TResource;
    res_goldIngot: TResource;

    res_slime: TResource;
    res_glass: TResource;
    res_cloth: TResource;
    res_cloud: TResource;
    res_gem: TResource;

    res_plank: TResource;
    res_stoneTile: TResource;
    res_door: TResource;
    res_window: TResource;
    res_torch: TResource;
    res_flint: TResource;
    res_bottle: TResource;
    // res_ale: TResource;

    grass: TTile;
    rock: TTile;
    water: TTile;
    flower: TTile;
    tree: TTile;
    dirt: TTile;
    sand: TTile;
    cactus: TTile;
    hole: TTile;
    treeSapling: TTile;
    cactusSapling: TTile;
    farmland: TTile;
    wheat: TTile;
    lava: TTile;
    stairsDown: TTile;
    stairsUp: TTile;
    infiniteFall: TTile;
    cloud: TTile;
    hardRock: TTile;
    ironOre: TTile;
    goldOre: TTile;
    gemOre: TTile;
    cloudCactus: TTile;

    woodenWall: TTile;
    rockWall: TTile;
    fence: TTile;
    rockFloor: TTile;
    door: TTile;
    window: TTile;

    constructor create;
    destructor Destroy; override;

    function tile(id: integer): TTile;
  end;

  TPlantableResource = class(TResource)
  private
    sourceTiles: TTileList;
    targetTile: TTile;
  public
    constructor create(name: string; sprite: integer; color: Cardinal;
      targetTile: TTile; Source: array of TTile);
    destructor Destroy; override;
    function interactOn(tile: TTile; level: TLevel; xt, yt: integer;
      player: TPlayer; attackDir: integer): Boolean; override;
  end;

  TFoodResource = class(TResource)
  private
    heal: integer;
    staminaCost: integer;
  public
    constructor create(name: string; sprite: integer; color: Cardinal;
      heal, staminaCost: integer);
    function interactOn(tile: TTile; level: TLevel; xt, yt: integer;
      player: TPlayer; attackDir: integer): Boolean; override;
  end;

  TToolType = class
    name: string;
    sprite: integer;
    constructor create(name: string; sprite: integer);
  end;

  TToolTypes = class
  public
    shovel: TToolType;
    hoe: TToolType;
    sword: TToolType;
    pickaxe: TToolType;
    axe: TToolType;

    constructor create;
    destructor Destroy; override;
  end;

  TListItem = class
    procedure renderInventory(const screen: TScreen; x, y: integer); virtual;
  end;

  TItem = class(TListItem)
  public
    function getColor: Cardinal; virtual;
    function getSprite: integer; virtual;

    procedure onTake(entity: TItemEntity); virtual;
    procedure renderInventory(const screen: TScreen; x, y: integer); override;

    function interact(player: TPlayer; entity: TEntity; attackDir: integer)
      : Boolean; virtual;

    procedure renderIcon(const screen: TScreen; const x, y: integer); virtual;

    function interactOn(const tile: TTile; const level: TLevel;
      const xt, yt: integer; const player: TPlayer; const attackDir: integer)
      : Boolean; virtual;

    function isDepleted(): Boolean; virtual;
    function canAttack(): Boolean; virtual;
    function getAttackDamageBonus(const e: TEntity): integer; virtual;

    function getName(): string; virtual;
    function matches(item: TItem): Boolean; virtual;
  end;

  TFurnitureItem = class(TItem)
  public
    placed: Boolean;
    Furniture: TFurniture;

    constructor create(const item: TFurniture);
    destructor Destroy; override;

    function getColor: Cardinal; override;
    function getSprite: integer; override;

    procedure onTake(entity: TItemEntity); override;
    procedure renderInventory(const screen: TScreen; x, y: integer); override;

    procedure renderIcon(const screen: TScreen; const x, y: integer); override;

    function interactOn(const tile: TTile; const level: TLevel;
      const xt, yt: integer; const player: TPlayer; const attackDir: integer)
      : Boolean; override;

    function isDepleted(): Boolean; override;
    function canAttack(): Boolean; override;

    function getName(): string; override;
  end;

  TPowerGloveItem = class(TItem)
  public
    function getColor: Cardinal; override;
    function getSprite: integer; override;
    procedure renderIcon(const screen: TScreen; const x, y: integer); override;
    procedure renderInventory(const screen: TScreen; x, y: integer); override;
    function getName(): string; override;
    function interact(player: TPlayer; entity: TEntity; attackDir: integer)
      : Boolean; override;
  end;

  TResourceItem = class(TItem)
  public
    Resource: TResource;
    count: integer;

    constructor create(const item: TResource); overload;
    constructor create(const item: TResource; count: integer); overload;

    function getColor: Cardinal; override;
    function getSprite: integer; override;

    procedure onTake(entity: TItemEntity); override;
    procedure renderInventory(const screen: TScreen; x, y: integer); override;

    procedure renderIcon(const screen: TScreen; const x, y: integer); override;

    function interactOn(const tile: TTile; const level: TLevel;
      const xt, yt: integer; const player: TPlayer; const attackDir: integer)
      : Boolean; override;

    function isDepleted(): Boolean; override;

    function getName(): string; override;
  end;

  TToolItem = class(TItem)
  private
    typ: TToolType;
    level: integer;
    names: array [0 .. 4] of string;
    colors: array [0 .. 4] of Cardinal;
  public
    constructor create(typ: TToolType; level: integer);
    destructor Destroy; override;
    function getColor: Cardinal; override;
    function getSprite: integer; override;

    procedure renderIcon(const screen: TScreen; const x, y: integer); override;
    procedure renderInventory(const screen: TScreen; x, y: integer); override;
    function getName(): string; override;
    procedure onTake(entity: TItemEntity); override;
    function canAttack(): Boolean; override;
    function getAttackDamageBonus(const e: TEntity): integer; override;
    function matches(item: TItem): Boolean; override;
  end;

  TTile = class
  public
    id: Byte;

    connectsToGrass: Boolean;
    connectsToSand: Boolean;
    connectsToLava: Boolean;
    connectsToWater: Boolean;
    connectsToPavement: Boolean;

    constructor create(const TileId: integer);
    procedure render(screen: TScreen; level: TLevel; x, y: integer); virtual;
    function getLightRadius(level: TLevel; x, y: integer): integer; virtual;
    procedure Tick(level: TLevel; xt, yt: integer); virtual;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; virtual;
    procedure hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
      dmg, attackDir: integer); overload; virtual;
    procedure hurt(level: TLevel; x, y, dmg: integer); overload; virtual;
    procedure bumpedInto(level: TLevel; xt, yt: integer;
      entity: TEntity); virtual;
    procedure steppedOn(level: TLevel; xt, yt: integer;
      entity: TEntity); virtual;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; virtual;
    function use(level: TLevel; xt, yt: integer; player: TPlayer;
      attackDir: integer): Boolean; virtual;
    function connectsToLiquid(): Boolean; virtual;

    function getVisibilityBlocking(level: TLevel; x, y: integer; e: TEntity)
      : integer; virtual;
    function getFireFuelAmount(level: TLevel; xt, yt: integer)
      : integer; virtual;
    procedure burnFireFuel(level: TLevel; xt, yt, burnPower: integer;
      ent: TEntity); virtual;
    function isFlammable(level: TLevel; xt, yt: integer): Boolean;
  end;

  THardRockTile = class(TTile)
  public
    constructor create(id: integer);

    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; override;
    procedure hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
      dmg, attackDir: integer); override;
    procedure hurt(level: TLevel; x, y, dmg: integer); override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
    procedure Tick(level: TLevel; xt, yt: integer); override;
  end;

  TInfiniteFallTile = class(TTile)
  public
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    procedure Tick(level: TLevel; xt, yt: integer); override;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; override;
  end;

  TStairsTile = class(TTile)
  private
    leadsUp: Boolean;
  public
    constructor create(id: integer; leadsUp: Boolean);
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
  end;

  TStoneTile = class(TTile)
  public
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; override;
  end;

  TSaplingTile = class(TTile)
  private
    growsTo, onType: TTile;
  public
    constructor create(id: integer; onType, growsTo: TTile);
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    procedure Tick(level: TLevel; xt, yt: integer); override;
    procedure hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
      dmg, attackDir: integer); override;

    function getFireFuelAmount(level: TLevel; xt, yt: integer)
      : integer; override;
    procedure burnFireFuel(level: TLevel; xt, yt, burnPower: integer;
      ent: TEntity); override;

  end;

  TFarmTile = class(TTile)
  public
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
    procedure Tick(level: TLevel; xt, yt: integer); override;
    procedure steppedOn(level: TLevel; xt, yt: integer;
      entity: TEntity); override;
  end;

  TDirtTile = class(TTile)
  public
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
  end;

  TCactusTile = class(TTile)
  public
    constructor create(id: integer);
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; override;
    procedure hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
      dmg, attackDir: integer); override;
    procedure Tick(level: TLevel; xt, yt: integer); override;
    procedure bumpedInto(level: TLevel; xt, yt: integer;
      entity: TEntity); override;
    function getVisibilityBlocking(level: TLevel; x, y: integer; e: TEntity)
      : integer; override;
  end;

  THoleTile = class(TTile)
  public
    constructor create(id: integer);
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; override;
  end;

  TRockTile = class(TTile)
  public
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; override;
    procedure hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
      dmg, attackDir: integer); override;
    procedure hurt(level: TLevel; x, y, dmg: integer); override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
    procedure Tick(level: TLevel; xt, yt: integer); override;
  end;

  TTreeTile = class(TTile)
  public
    constructor create(id: integer);
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    procedure Tick(level: TLevel; xt, yt: integer); override;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; override;
    procedure hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
      dmg, attackDir: integer); override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
    procedure hurt(level: TLevel; x, y, dmg: integer); override;

    function getVisibilityBlocking(level: TLevel; x, y: integer; e: TEntity)
      : integer; override;
    function getFireFuelAmount(level: TLevel; xt, yt: integer)
      : integer; override;
    procedure burnFireFuel(level: TLevel; xt, yt, burnPower: integer;
      ent: TEntity); override;
  end;

  TCloudTile = class(TTile)
  public
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
  end;

  TGrassTile = class(TTile)
  public
    constructor create(id: integer);
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    procedure Tick(level: TLevel; xt, yt: integer); override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
    function getVisibilityBlocking(level: TLevel; x, y: integer; e: TEntity)
      : integer; override;
    function getFireFuelAmount(level: TLevel; xt, yt: integer)
      : integer; override;
    procedure burnFireFuel(level: TLevel; xt, yt, burnPower: integer;
      ent: TEntity); override;
  end;

  TSandTile = class(TTile)
  public
    constructor create(id: integer);
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    procedure Tick(level: TLevel; xt, yt: integer); override;
    procedure steppedOn(level: TLevel; xt, yt: integer;
      entity: TEntity); override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
  end;

  TWheatTile = class(TTile)
  private
    procedure harvest(level: TLevel; x, y: integer);
  public
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    procedure Tick(level: TLevel; xt, yt: integer); override;
    procedure steppedOn(level: TLevel; xt, yt: integer;
      entity: TEntity); override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
    procedure hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
      dmg, attackDir: integer); override;
    function getFireFuelAmount(level: TLevel; xt, yt: integer)
      : integer; override;
    procedure burnFireFuel(level: TLevel; xt, yt, burnPower: integer;
      ent: TEntity); override;
  end;

  TCloudCactusTile = class(TTile)
  public
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; override;
    procedure hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
      dmg, attackDir: integer); override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
    procedure hurt(level: TLevel; x, y, dmg: integer); overload; override;
    procedure bumpedInto(level: TLevel; xt, yt: integer;
      entity: TEntity); override;
  end;

  TFlowerTile = class(TGrassTile)
  public
    constructor create(id: integer);
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
    procedure hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
      dmg, attackDir: integer); override;
    function getFireFuelAmount(level: TLevel; xt, yt: integer)
      : integer; override;
    procedure burnFireFuel(level: TLevel; xt, yt, burnPower: integer;
      ent: TEntity); override;
  end;

  TOreTile = class(TTile)
  private
    toDrop: TResource;
    color: Cardinal;
  public
    constructor create(id: integer; toDrop: TResource);
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; override;
    procedure hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
      dmg, attackDir: integer); override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
    procedure hurt(level: TLevel; x, y, dmg: integer); overload; override;
    procedure bumpedInto(level: TLevel; xt, yt: integer;
      entity: TEntity); override;
  end;

  TWaterTile = class(TTile)
  public
    constructor create(id: integer);
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; override;
    procedure Tick(level: TLevel; xt, yt: integer); override;
    function getVisibilityBlocking(level: TLevel; x: integer; y: integer;
      e: TEntity): integer; override;

  end;

  TLavaTile = class(TTile)
  public
    constructor create(id: integer);
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; override;
    procedure Tick(level: TLevel; xt, yt: integer); override;
    function getLightRadius(level: TLevel; x, y: integer): integer; override;
  end;

  TWoodenWallTile = class(TTile)
  public
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; override;
    procedure hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
      dmg, attackDir: integer); override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
    procedure hurt(level: TLevel; x, y, dmg: integer); overload; override;
    procedure Tick(level: TLevel; xt, yt: integer); override;
    function getFireFuelAmount(level: TLevel; xt, yt: integer)
      : integer; override;
    procedure burnFireFuel(level: TLevel; xt, yt, burnPower: integer;
      ent: TEntity); override;
  end;

  TDoorTile = class(TTile)
  private
    FOnType: TTile;
  public
    constructor create(id: integer); overload;
    constructor create(id: integer; onType: TTile); overload;
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
    function use(level: TLevel; xt, yt: integer; player: TPlayer;
      attackDir: integer): Boolean; override;
    procedure hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
      dmg, attackDir: integer); override;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; override;
    function getFireFuelAmount(level: TLevel; xt, yt: integer)
      : integer; override;
    procedure burnFireFuel(level: TLevel; xt, yt, burnPower: integer;
      ent: TEntity); override;
  end;

  TFenceTile = class(TTile)
  public
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    procedure hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
      dmg, attackDir: integer); overload; override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
    procedure hurt(level: TLevel; x, y, dmg: integer); overload; override;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; override;
    function getVisibilityBlocking(level: TLevel; x, y: integer; e: TEntity)
      : integer; override;
    function getFireFuelAmount(level: TLevel; xt, yt: integer)
      : integer; override;
    procedure burnFireFuel(level: TLevel; xt, yt, burnPower: integer;
      ent: TEntity); override;
  end;

  TRockWallTile = class(TTile)
  public
    constructor create(id: integer);
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    procedure hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
      dmg, attackDir: integer); overload; override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
    procedure hurt(level: TLevel; x, y, dmg: integer); overload; override;
    procedure Tick(level: TLevel; xt, yt: integer); override;
    function mayPass(level: TLevel; x, y: integer; e: TEntity)
      : Boolean; override;
  end;

  TWindowTile = class(TTile)
  private
    FOnType: TTile;
    FOpened: Boolean;
    FLocked: Boolean;
  public
    constructor create(id: integer); overload;
    constructor create(id: integer; onType: TTile); overload;
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
    procedure hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
      dmg, attackDir: integer); override;
    function getVisibilityBlocking(level: TLevel; x, y: integer; e: TEntity)
      : integer; override;
    function getFireFuelAmount(level: TLevel; xt, yt: integer)
      : integer; override;
    procedure burnFireFuel(level: TLevel; xt, yt, burnPower: integer;
      ent: TEntity); override;
  end;

  TRockFloorTile = class(TTile)
  public
    constructor create(id: integer);
    procedure render(screen: TScreen; level: TLevel; x, y: integer); override;
    function interact(level: TLevel; xt, yt: integer; player: TPlayer;
      item: TItem; attackDir: integer): Boolean; override;
  end;
  // ---------------------------------------------------------------------------

  TEntity = class
  protected
    function move2(xa, ya: integer): Boolean; virtual;
    procedure touchedBy(entity: TEntity); virtual;
    function distanceFrom(entity: TEntity): integer;
  public
    x, y: integer;
    xr: integer;
    yr: integer;
    removed: Boolean;
    level: TLevel;

    constructor create;
    procedure render(screen: TScreen); virtual;
    procedure Tick(); virtual;
    procedure remove(); virtual;
    procedure init(level: TLevel); virtual;
    function intersects(const x0, y0, x1, y1: integer): Boolean; virtual;
    function blocks(e: TEntity): Boolean; virtual;
    procedure hurt(mob: TLivingEntity; const dmg, attackDir: integer);
      overload; virtual;
    procedure hurt(tile: TTile; const x, y, dmg: integer); overload; virtual;
    function move(xa, ya: integer): Boolean; virtual;
    function isBlockableBy(mob: TMob): Boolean; virtual;
    procedure touchItem(ItemEntity: TItemEntity); virtual;
    function canSwim(): Boolean; virtual;
    function interact(player: TPlayer; item: TItem; attackDir: integer)
      : Boolean; virtual;
    function use(player: TPlayer; attackDir: integer): Boolean; virtual;
    function getLightRadius(): integer; virtual;

  end;

  TItemEntity = class(TEntity)
  private
    lifeTime: integer;
    time: integer;
  protected
    walkDist: integer;
    dir: integer;
    xKnockback, yKnockback: integer;
  public
    hurtTime: integer;
    xa, ya, za: single;
    xx, yy, zz: single;
    item: TItem;

    constructor create(item: TItem; x, y: integer);
    destructor Destroy; override;

    procedure Tick; override;
    function isBlockableBy(mob: TMob): Boolean; override;
    procedure render(screen: TScreen); override;
    procedure touchedBy(entity: TEntity); override;

    procedure take(player: TPlayer); virtual;
  end;

  TLivingEntity = class(TEntity)
  protected
    walkDist: integer;
    dir: integer;
    xKnockback: integer;
    yKnockback: integer;
    lvl: integer;

    procedure die(); virtual;
    function isSwimming(): Boolean; virtual;
    procedure doHurt(damage, attackDir: integer); virtual;
  public
    hurtTime: integer;
    maxHealth: integer;
    health: integer;
    swimTimer: integer;
    tickTime: integer;
    karma: integer;
    constructor create;
    procedure Tick(); override;
    function move(xa, ya: integer): Boolean; override;
    procedure hurt(mob: TLivingEntity; const dmg, attackDir: integer);
      overload; override;
    procedure hurt(tile: TTile; const x, y, dmg: integer); overload; override;
    procedure heal(heal: integer); virtual;
    function findStartPos(level: TLevel): Boolean; virtual;

    function getFacingTileX(): integer; virtual;
    function getFacingTileY(): integer; virtual;
    function getFacingTile(): TTile; virtual;

    function getKarma(): integer;
    function isGood(): Boolean;
    function isEvil(): Boolean;
    function isNeutral(): Boolean;
  end;

  TMob = class(TLivingEntity)
  public
    constructor create;
    function blocks(e: TEntity): Boolean; override;
  end;

  TNPC = class(TLivingEntity)
  public
    constructor create;
  end;

  TWanderer = class(TNPC)
  private
    xa, ya: integer;
    randomWalkTime: integer;
    idleTime: integer;
  protected
    procedure die(); override;
  public
    constructor create(lvl: integer);
    procedure Tick(); override;
    procedure render(screen: TScreen); override;
    procedure touchedBy(entity: TEntity); override;
  end;

  TSlime = class(TMob)
  private
    xa, ya: integer;
    jumpTime: integer;
  protected
    procedure die(); override;
  public
    constructor create(lvl: integer);
    procedure Tick(); override;
    procedure render(screen: TScreen); override;
    procedure touchedBy(entity: TEntity); override;
  end;

  TZombie = class(TMob)
  private
    xa, ya: integer;
    randomWalkTime: integer;
  public
    constructor create(lvl: integer);
    procedure Tick(); override;
    procedure die(); override;
    procedure render(screen: TScreen); override;
    procedure touchedBy(entity: TEntity); override;
  end;

  TAirwizard = class(TMob)
  private
    xa, ya: integer;
    randomWalkTime: integer;
    attackDelay: integer;
    attackTime: integer;
    attackType: integer;
  protected
    procedure doHurt(damage, attackDir: integer); override;
  public
    constructor create;
    procedure Tick(); override;
    procedure die(); override;
    procedure render(screen: TScreen); override;
    procedure touchedBy(entity: TEntity); override;
  end;

  TPlayer = class(TMob)
  private
    input: TInputHandler;
    attackTime, attackDir: integer;
    onStairDelay: integer;
    function myuse: Boolean; overload;
    function myuse(x0, y0, x1, y1: integer): Boolean; overload;
    function myinteract(x0, y0, x1, y1: integer): Boolean;

    procedure attack;

    procedure hurt(x0, y0, x1, y1: integer); overload;
    function getAttackDamage(e: TEntity): integer;
  protected
    procedure doHurt(damage, attackDir: integer); override;
  public
    game: TGame;
    inventory: TInventory;
    attackItem: TItem;
    activeItem: TItem;
    stamina: integer;
    staminaRecharge: integer;
    staminaRechargeDelay: integer;
    score: integer;
    maxstamina: integer;
    invulnerableTime: integer;

    constructor create(game: TGame; input: TInputHandler);
    destructor Destroy; override;
    procedure Tick(); override;
    procedure render(screen: TScreen); override;
    procedure changeLevel(dir: integer);

    procedure touchItem(ItemEntity: TItemEntity); override;
    function canSwim(): Boolean; override;
    function getLightRadius(): integer; override;
    procedure die(); override;
    function findStartPos(level: TLevel): Boolean; override;
    function payStamina(cost: integer): Boolean;
    procedure touchedBy(entity: TEntity); override;
    procedure GameWon;
  end;

  TSpark = class(TEntity)
  private
    lifeTime: integer;
    time: integer;
    owner: TAirwizard;
  public
    xa, ya: single;
    xx, yy: single;
    constructor create(owner: TAirwizard; xa, ya: single);
    procedure Tick(); override;
    function isBlockableBy(mob: TMob): Boolean; override;
    procedure render(screen: TScreen); override;
  end;

  TFire = class(TEntity)
  private
    time: integer;
  protected
    owner: TLivingEntity;
    burnPower: integer;
    burnCycle: integer;
    renderFlip: integer;
    renderImg: integer;

    procedure BurnFuel(); virtual;
    procedure TrySpreading(); virtual;
    procedure harmNearbyEntities(); virtual;
  public
    constructor create; overload;
    constructor create(owner: TLivingEntity; x, y: integer); overload;
    constructor create(owner: TLivingEntity;
      x, y, burnPower, burnCycle: integer); overload;

    procedure Tick(); override;
    function isBlockableBy(mob: TMob): Boolean; override;
    procedure render(screen: TScreen); override;
    function getLightRadius(): integer; override;

  end;

  TTorch = class(TFire)
  protected
    burnCapacity: integer;

    procedure BurnFuel; override;
    procedure TrySpreading(); override;
    procedure harmNearbyEntities(); override;
  public
    constructor create(owner: TLivingEntity; x, y: integer;
      burnCapacity: integer = 10; burnPower: integer = 1;
      burnCycle: integer = 1000);
    procedure render(screen: TScreen); override;
    procedure hurt(mob: TLivingEntity; const dmg, attackDir: integer); override;

    function use(player: TPlayer; atackdir: integer): Boolean; override;
    function getLightRadius(): integer; override;
  end;

  TFurnitureClass = class of TFurniture;

  TFurniture = class(TEntity)
  private
    pushTime: integer;
    pushDir: integer;
    shouldTake: TPlayer;
  protected
    procedure touchedBy(entity: TEntity); override;
    procedure InitSprite; virtual;
  public
    name: string;
    col: Cardinal;
    sprite: integer;

    constructor create;
    procedure Tick(); override;
    procedure render(screen: TScreen); override;
    function blocks(e: TEntity): Boolean; override;

    procedure take(player: TPlayer); virtual;
  end;

  TWorkbench = class(TFurniture)
  protected
    procedure InitSprite; override;
  public
    function use(player: TPlayer; attackDir: integer): Boolean; override;
  end;

  TFurnace = class(TFurniture)
  protected
    procedure InitSprite; override;
  public
    function use(player: TPlayer; attackDir: integer): Boolean; override;
  end;

  TAnvil = class(TFurniture)
  protected
    procedure InitSprite; override;
  public
    function use(player: TPlayer; attackDir: integer): Boolean; override;
  end;

  { TBrewery = class(TFurniture)
    protected
    procedure InitSprite; override;
    public
    function use(player: TPlayer; attackDir: integer): Boolean; override;
    end;
  }
  TOven = class(TFurniture)
  protected
    procedure InitSprite; override;
  public

    function use(player: TPlayer; attackDir: integer): Boolean; override;
  end;

  TChest = class(TFurniture)
  protected
    procedure InitSprite; override;
  public
    inventory: TInventory;

    destructor Destroy; override;
    function use(player: TPlayer; attackDir: integer): Boolean; override;
  end;

  TLantern = class(TFurniture)
  protected
    procedure InitSprite; override;
  public
    function getLightRadius(): integer; override;
  end;

  TParticle = class(TEntity)
  public
    procedure Tick(); override;
  end;

  TTextParticle = class(TParticle)
  private
    msg: string;
    col: Cardinal;
    time: integer;
  public
    xa, ya, za: single;
    xx, yy, zz: single;

    constructor create(msg: string; x, y: integer; col: Cardinal);
    procedure Tick(); override;
    procedure render(screen: TScreen); override;
  end;

  TSmashParticle = class(TParticle)
  private
    time: integer;
  public
    constructor create(x, y: integer);
    procedure Tick(); override;
    procedure render(screen: TScreen); override;
  end;

  TInventory = class
  private
    function findResource(Resource: TResource): TResourceItem;
  public
    Items: TItemList;
    constructor create;
    destructor Destroy; override;

    procedure add(item: TListItem); overload;
    procedure add(slot: integer; item: TListItem); overload;
    function hasResources(r: TResource; count: integer): Boolean;
    function removeResource(r: TResource; count: integer): Boolean;
    function count(item: TItem): integer;
  end;

  // Recipes
  TRecipe = class(TListItem)
  public
    costs: TResourceList;
    canCraft: Boolean;
    resultTemplate: TItem;

    constructor create(resultTemplate: TItem);
    destructor Destroy; override;

    function addCost(Resource: TResource; count: integer): TRecipe; virtual;
    procedure checkCanCraft(player: TPlayer); virtual;
    procedure renderInventory(const screen: TScreen; x, y: integer); override;
    procedure craft(player: TPlayer); virtual;
    procedure deductCost(player: TPlayer); virtual;
  end;

  TFurnitureRecipe = class(TRecipe)
  private
    item: TFurnitureItem;
  public
    constructor create(const Furniture: TFurnitureClass);
    destructor Destroy; override;
    procedure craft(player: TPlayer); override;
  end;

  TResourceRecipe = class(TRecipe)
  private
    Resource: TResource;
    count: integer;
  public
    constructor create(Resource: TResource; count: integer = 1);
    procedure craft(player: TPlayer); override;
  end;

  TToolRecipe = class(TRecipe)
  private
    typ: TToolType;
    level: integer;
  public
    constructor create(typ: TToolType; level: integer);
    procedure craft(player: TPlayer); override;
  end;

  TCrafting = class
  public
    anvilRecipes: TRecipeList;
    ovenRecipes: TRecipeList;
    furnaceRecipes: TRecipeList;
    workbenchRecipes: TRecipeList;
    // breweryRecipes: TRecipeList;

    constructor create;
    destructor Destroy; override;
  end;

  // ---------- Screen related -------------------------------------------------
  TSpriteSheet = class;

  TScreen = class
  private
    sheet: TSpriteSheet;
  public
    xOffset: integer;
    yOffset: integer;

    w, h: integer;
    pixels: TGamePixelBuffer;

    constructor create(const _w, _h: integer; _Sheet: TSpriteSheet);
    destructor Destroy; override;

    procedure clear(const color: Cardinal);

    procedure render(xp, yp: integer; const tile: integer;
      const colors, bits: Cardinal);

    procedure setOffset(const _xOffset, _yOffset: integer);

    procedure overlay(screen2: TScreen; const xa, ya: integer);
    procedure copyRect(screen2: TScreen; const x2, y2, w2, h2: integer);
    procedure renderLight(x, y, r: integer);
    procedure renderPoint(xp, yp, size: integer; col: cardinal);

    function GetPixel(const x, y: integer): integer;
  end;

  TSpriteSheet = class
    Width, Height: integer;
    pixels: TGamePixelBuffer;

    constructor create(const w, h: integer; const image: TGamePixelBuffer);
    destructor Destroy; override;
  end;

  TSprite = class
    x, y: integer;
    img: integer;
    col: Cardinal;
    bits: integer;

    constructor create(const x, y, img: integer; col: Cardinal; bits: integer);
  end;

  TFont = class
    procedure draw(msg: string; const screen: TScreen; const x, y: integer;
      const col: Cardinal);
    procedure renderFrame(const screen: TScreen; const title: string;
      const x0, y0, x1, y1: integer);
  end;

  TMenu = class
  protected
    game: TGame;
    input: TInputHandler;
  public
    procedure init(game: TGame; input: TInputHandler);
    procedure Tick(); virtual;
    procedure render(screen: TScreen); virtual;
    procedure renderItemList(screen: TScreen; xo, yo, x1, y1: integer;
      listItems: TItemList; selected: integer); virtual;
    function MouseClick(const x, y: integer): Boolean; virtual;
  end;

  TCraftingMenu = class(TMenu)
  private
    player: TPlayer;
    selected: integer;
    recipes: TRecipeList;
  public
    constructor create(recipes: TRecipeList; player: TPlayer);
    procedure Tick(); override;
    procedure render(screen: TScreen); override;
  end;

  TAboutMenu = class(TMenu)
  private
    parent: TMenu;
    tickCount: integer;
  public
    constructor create(parent: TMenu);
    procedure Tick(); override;
    procedure render(screen: TScreen); override;
    function MouseClick(const x, y: integer): Boolean; override;
  end;

  TDeadMenu = class(TMenu)
  private
    inputDelay: integer;
  public
    constructor create;
    function MouseClick(const x, y: integer): Boolean; override;
    procedure Tick(); override;
    procedure render(screen: TScreen); override;
  end;

  TWonMenu = class(TMenu)
  private
    inputDelay: integer;
  public
    constructor create;
    function MouseClick(const x, y: integer): Boolean; override;
    procedure Tick(); override;
    procedure render(screen: TScreen); override;
  end;

  TTitleMenu = class(TMenu)
  private
    selected: integer;
    options: array [0 .. 2] of string;

    procedure ClickSelect();
  public
    constructor create;
    procedure Tick(); override;
    procedure render(screen: TScreen); override;

    function MouseClick(const x, y: integer): Boolean; override;
  end;

  TContainerMenu = class(TMenu)
  private
    player: TPlayer;
    container: TInventory;
    selected: integer;
    title: string;
    oSelected: integer;
    window: integer;
  public
    constructor create(player: TPlayer; title: string; container: TInventory);
    procedure Tick(); override;
    procedure render(screen: TScreen); override;
  end;

  TInventoryMenu = class(TMenu)
  private
    player: TPlayer;
    selected: integer;
  public
    constructor create(player: TPlayer);
    procedure Tick(); override;
    procedure render(screen: TScreen); override;
  end;

  TInstructionsMenu = class(TMenu)
  private
    parent: TMenu;
  public
    function MouseClick(const x, y: integer): Boolean; override;
    constructor create(parent: TMenu);
    procedure Tick(); override;
    procedure render(screen: TScreen); override;
  end;

  TLevelTransitionMenu = class(TMenu)
  private
    dir, time: integer;
  public
    constructor create(dir: integer);
    procedure Tick(); override;
    procedure render(screen: TScreen); override;
  end;

  // --- Game --------------------------------------------------------------------
  TGame = class(TThread)
  private
    FInitGame: Boolean;
    FMenu: TMenu;
    FLastTime: Cardinal;

    FPixels: TGamePixelBuffer;
{$IFDEF XE5}
    FCriticalSection: TCriticalSection;
{$ELSE}
    FCriticalSection: TRTLCriticalSection;
{$ENDIF}
    screen: TScreen;
    lightScreen: TScreen;

    colors: array [0 .. 255] of Cardinal;

    tickCount, gametime: integer;
    level: TLevel;
    levels: array [0 .. 4] of TLevel;
    player: TPlayer;
    currentLevel: integer;
    playerDeadTime: integer;
    pendingLevelChange: integer;
    wonTimer: integer;

{$IFDEF ANIMATEDABOUT}
    miniGame: TLevel;
    miniScreen: TScreen;
    FMiniGameWidth: integer;
    FMiniGameHeight: integer;
{$ENDIF}
    FGameWidth: integer;
    FGameHeight: integer;

    procedure FreeLevels;
    procedure renderGui(const Messages: Array of String);
    procedure renderFocusNagger();
    procedure render(const Messages: Array of String);

    procedure Tick();
    procedure Loading(const Percentage: integer);

    function GetDayCycle(): single;
    function GetMenuVisible(): Boolean;
  protected
    procedure Execute; override;
  public
    hasWon: Boolean;
    hasFocus: Boolean;
    FogOfWar: Boolean;

    input: TInputHandler;

    constructor create(const Width, Height: integer;
      const Graphics: TGamePixelBuffer; const GameWidth, GameHeight: integer);
    destructor Destroy; override;
    procedure setMenu(menu: TMenu);

    procedure won();
    procedure resetGame;

    procedure changeLevel(dir: integer);
    procedure scheduleLevelChange(dir: integer);

    procedure RenderBitmap(const Bitmap: TBitmap);

    function MouseClick(const x, y: integer): Boolean;

    property MenuVisible: Boolean read GetMenuVisible;
  end;

function Resources: TResources;
function Tooltypes: TToolTypes;
function Crafting: TCrafting;
function Font: TFont;

implementation

uses
  SysUtils, Math, FMX.Utils, USound;

{$IFDEF XE5}

function GetTickCount: Cardinal;
begin
  Result := TThread.GetTickCount;
end;
{$ENDIF}

function IsInRect(const rx1, ry1, rx2, ry2: integer; const x, y: integer)
  : Boolean; inline;
begin
  Result := (x >= rx1 * 8) and (x <= rx2 * 8) and (y >= ry1 * 8) and
    (y <= ry2 * 8);
end;

procedure DoRandSeed(const x, y: integer);
begin
  randSeed := integer(GetTickCount shr 8) + x shl 8 + y shl 10;
end;

const
  BIT_MIRROR_X = $01;
  BIT_MIRROR_Y = $02;
  dither: array [0 .. 15] of Byte = (0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15,
    7, 13, 5);

var
  FResources: TResources;
  FTooltypes: TToolTypes;
  FCrafting: TCrafting;
  FFont: TFont;

  NextGaussian: single = -1;

function CharFromStr(const Str: string; const i: integer): Char;
begin
{$IFDEF NEXTGEN}
  Result := Str[i];
{$ELSE}
  Result := Str[i + 1];
{$ENDIF}
end;

function Font: TFont;
begin
  if not assigned(FFont) then
    FFont := TFont.create;
  Result := FFont;
end;

function CalcColor(const d: integer): Cardinal; overload;
var
  r, g, b: Byte;
begin
  if (d < 0) then
  begin
    Result := 255;
    exit;
  end;
  r := d div 100 mod 10;
  g := d div 10 mod 10;
  b := d mod 10;
  Result := r * 36 + g * 6 + b;
end;

function CalcColor(const a, b, c, d: integer): Cardinal; overload;
begin
  Result := (CalcColor(d) shl 24) + (CalcColor(c) shl 16) + (CalcColor(b) shl 8)
    + (CalcColor(a));
end;

function Resources: TResources;
begin
  if not assigned(FResources) then
    FResources := TResources.create;
  Result := FResources;
end;

function Tooltypes: TToolTypes;
begin
  if not assigned(FTooltypes) then
    FTooltypes := TToolTypes.create;
  Result := FTooltypes;
end;

function Crafting: TCrafting;
begin
  if not assigned(FCrafting) then
    FCrafting := TCrafting.create;
  Result := FCrafting;
end;

function RandomFloat: single;
begin
  Result := random(100) / 100;
end;

function RandomGaussian: single;
var
  multiplier, v1, v2, s: single;
begin
  if (NextGaussian > -1) then
  begin
    Result := NextGaussian;
    NextGaussian := -1;
  end
  else
  begin
    repeat
      v1 := 2 * random(100) / 100 - 1; // between   -1.0   and   1.0
      v2 := 2 * random(100) / 100 - 1; // between   -1.0   and   1.0
      s := v1 * v1 + v2 * v2;
    until (s > 0) and (s < 1);
    multiplier := sqrt(-2 * log10(s) / s);
    NextGaussian := v2 * multiplier;
    Result := v1 * multiplier;
  end;
end;

function LevelSortCompare(e0, e1: Pointer): integer;
begin
  if (TEntity(e1).y < TEntity(e1).y) then
    Result := 1
  else if (TEntity(e1).y > TEntity(e0).y) then
    Result := -1
  else
    Result := 0;
end;

{ TLevelGen }

constructor TLevelGen.create(const w, h, featureSize: integer);
var
  stepSize, y, x: integer;
  scale, scaleMod: single;
  halfstep: integer;
  a, b, c, d, e, f, g, i: single;
begin
  self.w := w;
  self.h := h;

  Setlength(values, w * h);

  y := 0;
  while y < w do
  begin
    x := 0;
    while x < w do
    begin
      setSample(x, y, RandomFloat * 2 - 1);
      inc(x, featureSize);
    end;
    y := y + featureSize;
  end;

  stepSize := featureSize;
  scale := 1.0 / w;
  scaleMod := 1;
  repeat
    halfstep := stepSize div 2;
    y := 0;
    while y < w do
    begin
      x := 0;
      while x < w do
      begin
        a := sample(x, y);
        b := sample(x + stepSize, y);
        c := sample(x, y + stepSize);
        d := sample(x + stepSize, y + stepSize);

        e := (a + b + c + d) / 4.0 + (RandomFloat * 2 - 1) * stepSize * scale;
        setSample(x + halfstep, y + halfstep, e);
        x := x + stepSize
      end;
      y := y + stepSize;
    end;

    y := 0;
    while y < w do
    begin
      x := 0;
      while x < w do
      begin
        a := sample(x, y);
        b := sample(x + stepSize, y);
        c := sample(x, y + stepSize);
        d := sample(x + halfstep, y + halfstep);
        e := sample(x + halfstep, y - halfstep);
        f := sample(x - halfstep, y + halfstep);

        i := (a + b + d + e) / 4.0 + (RandomFloat * 2 - 1) * stepSize *
          scale * 0.5;
        g := (a + c + d + f) / 4.0 + (RandomFloat * 2 - 1) * stepSize *
          scale * 0.5;
        setSample(x + halfstep, y, i);
        setSample(x, y + halfstep, g);
        x := x + stepSize;
      end;
      y := y + stepSize;
    end;
    stepSize := stepSize div 2;
    scale := scale * (scaleMod + 0.8);
    scaleMod := scaleMod * 0.3;
  until stepSize < 1;
end;

destructor TLevelGen.Destroy;
begin
  Setlength(values, 0);
  inherited;
end;

function TLevelGen.sample(const x, y: integer): single;
begin
  Result := values[(x and (w - 1)) + (y and (h - 1)) * w];
end;

procedure TLevelGen.setSample(const x, y: integer; value: single);
begin
  values[(x and (w - 1)) + (y and (h - 1)) * w] := value;
end;

function FindInMap(const x, y, w: integer; const map: TByteArray;
  const tile: TTile): Boolean;
var
  yy, xx: integer;
begin
  Result := false;
  for yy := y - 1 to y + 1 do
    for xx := x - 1 to x + 1 do
      if (map[xx + yy * w] <> tile.id) then
      begin
        Result := true;
        exit;
      end;
end;

procedure createTopMap(const w, h: integer; var map, data: TByteArray);
var
  mnoise1, mnoise2, mnoise3: TLevelGen;
  noise1, noise2: TLevelGen;
  x, y, i, j: integer;
  xd, yd, val, mval: single;
  dist: single;
  xo, yo, k, xs, ys: integer;
  col: Cardinal;
  xx, yy: integer;
  count: integer;
begin
  mnoise1 := TLevelGen.create(w, h, 16);
  mnoise2 := TLevelGen.create(w, h, 16);
  mnoise3 := TLevelGen.create(w, h, 16);

  noise1 := TLevelGen.create(w, h, 32);
  noise2 := TLevelGen.create(w, h, 32);

  for y := 0 to h - 1 do
  begin
    for x := 0 to w - 1 do
    begin
      i := x + y * w;

      val := abs(noise1.values[i] - noise2.values[i]) * 3 - 2;
      mval := abs(mnoise1.values[i] - mnoise2.values[i]);
      mval := abs(mval - mnoise3.values[i]) * 3 - 2;

      xd := x / (w - 1.0) * 2 - 1;
      yd := y / (h - 1.0) * 2 - 1;
      if (xd < 0) then
        xd := -xd;
      if (yd < 0) then
        yd := -yd;

      if xd >= yd then
        dist := xd
      else
        dist := yd;
      dist := dist * dist * dist * dist;
      dist := dist * dist * dist * dist;
      val := val + 1 - dist * 20;

      if (val < -0.5) then
        map[i] := Resources.water.id
      else if (val > 0.5) and (mval < -1.5) then
        map[i] := Resources.rock.id
      else
        map[i] := Resources.grass.id;
    end;
  end;

  for i := 0 to (w * h div 2800) - 1 do
  begin
    xs := random(w);
    ys := random(h);
    for k := 0 to 9 do
    begin
      x := xs + random(21) - 10;
      y := ys + random(21) - 10;
      for j := 0 to 99 do
      begin
        xo := x + random(5) - random(5);
        yo := y + random(5) - random(5);
        for yy := yo - 1 to yo + 1 do
          for xx := xo - 1 to xo + 1 do
            if (xx >= 0) and (yy >= 0) and (xx < w) and (yy < h) then
            begin
              if (map[xx + yy * w] = Resources.grass.id) then
              begin
                map[xx + yy * w] := Resources.sand.id;
              end;
            end;
      end;
    end;
  end;

  for i := 0 to w * h div 400 - 1 do
  begin
    x := random(w);
    y := random(h);
    for j := 0 to 199 do
    begin
      xx := x + random(15) - random(15);
      yy := y + random(15) - random(15);
      if (xx >= 0) and (yy >= 0) and (xx < w) and (yy < h) then
      begin
        if (map[xx + yy * w] = Resources.grass.id) then
        begin
          map[xx + yy * w] := Resources.tree.id;
        end;
      end;
    end;
  end;

  for i := 0 to w * h div 400 - 1 do
  begin
    x := random(w);
    y := random(h);
    col := random(4);
    for j := 0 to 29 do
    begin
      xx := x + random(5) - random(5);
      yy := y + random(5) - random(5);
      if (xx >= 0) and (yy >= 0) and (xx < w) and (yy < h) then
      begin
        if (map[xx + yy * w] = Resources.grass.id) then
        begin
          map[xx + yy * w] := Resources.flower.id;
          data[xx + yy * w] := Byte(col + Cardinal(random(4) * 16));
        end;
      end;
    end;
  end;

  for i := 0 to w * h div 100 - 1 do
  begin
    xx := random(w);
    yy := random(h);
    if (xx >= 0) and (yy >= 0) and (xx < w) and (yy < h) then
    begin
      if (map[xx + yy * w] = Resources.sand.id) then
      begin
        map[xx + yy * w] := Resources.cactus.id;
      end;
    end;
  end;

  count := 0;
  for i := 0 to (w * h div 100) - 1 do
  begin
    x := random(w - 2) + 1;
    y := random(h - 2) + 1;
    if FindInMap(x, y, w, map, Resources.rock) then
    begin
      map[x + y * w] := Resources.stairsDown.id;
      inc(count);
      if (count = 4) then
        break;
    end;
  end;

  FreeAndNil(mnoise1);
  FreeAndNil(mnoise2);
  FreeAndNil(mnoise3);

  FreeAndNil(noise1);
  FreeAndNil(noise2);
end;

procedure createUndergroundMap(const w, h, depth: integer;
  var map, data: TByteArray);
var
  mnoise1, mnoise2, mnoise3: TLevelGen;
  nnoise1, nnoise2, nnoise3: TLevelGen;
  wnoise1, wnoise2, wnoise3: TLevelGen;
  noise1, noise2: TLevelGen;
  count, xx, yy, r, x, y, i, j: integer;
  dist, val, nval, mval, wval: single;
  xd, yd: single;
begin
  mnoise1 := TLevelGen.create(w, h, 16);
  mnoise2 := TLevelGen.create(w, h, 16);
  mnoise3 := TLevelGen.create(w, h, 16);

  nnoise1 := TLevelGen.create(w, h, 16);
  nnoise2 := TLevelGen.create(w, h, 16);
  nnoise3 := TLevelGen.create(w, h, 16);

  wnoise1 := TLevelGen.create(w, h, 16);
  wnoise2 := TLevelGen.create(w, h, 16);
  wnoise3 := TLevelGen.create(w, h, 16);

  noise1 := TLevelGen.create(w, h, 32);
  noise2 := TLevelGen.create(w, h, 32);

  for y := 0 to h - 1 do
  begin
    for x := 0 to w - 1 do
    begin
      i := x + y * w;

      val := abs(noise1.values[i] - noise2.values[i]) * 3 - 2;

      mval := abs(mnoise1.values[i] - mnoise2.values[i]);
      mval := abs(mval - mnoise3.values[i]) * 3 - 2;

      nval := abs(nnoise1.values[i] - nnoise2.values[i]);
      nval := abs(nval - nnoise3.values[i]) * 3 - 2;

      wval := abs(wnoise1.values[i] - wnoise2.values[i]);
      wval := abs(wval - wnoise3.values[i]) * 3 - 2;

      xd := x / (w - 1.0) * 2 - 1;
      yd := y / (h - 1.0) * 2 - 1;
      if (xd < 0) then
        xd := -xd;
      if (yd < 0) then
        yd := -yd;

      if xd >= yd then
        dist := xd
      else
        dist := yd;
      dist := dist * dist * dist * dist;
      dist := dist * dist * dist * dist;
      val := val + 1 - dist * 20;

      if (val > -2) and (wval < -2.0 + (depth) / 2 * 3) then
      begin
        if (depth > 2) then
          map[i] := Resources.lava.id
        else
          map[i] := Resources.water.id;
      end
      else if (val > -2) and ((mval < -1.7) or (nval < -1.4)) then
      begin
        map[i] := Resources.dirt.id;
      end
      else
      begin
        map[i] := Resources.rock.id;
      end;
    end;
  end;

  r := 2;
  for i := 0 to (w * h div 400) - 1 do
  begin
    x := random(w);
    y := random(h);
    for j := 0 to 29 do
    begin
      xx := x + random(5) - random(5);
      yy := y + random(5) - random(5);
      if (xx >= r) and (yy >= r) and (xx < w - r) and (yy < h - r) then
      begin
        if (map[xx + yy * w] = Resources.rock.id) then
        begin
          map[xx + yy * w] := Byte((Resources.ironOre.id and $FF) + depth - 1);
        end;
      end;
    end;
  end;

  if (depth < 3) then
  begin
    count := 0;
    for i := 0 to (w * h div 100) - 1 do
    begin
      x := random(w - 20) + 10;
      y := random(h - 20) + 10;

      if FindInMap(x, y, w, map, Resources.rock) then
      begin
        map[x + y * w] := Resources.stairsDown.id;
        inc(count);
      end;
      if (count = 4) then
        break;
    end;
  end;

  FreeAndNil(mnoise1);
  FreeAndNil(mnoise2);
  FreeAndNil(mnoise3);

  FreeAndNil(nnoise1);
  FreeAndNil(nnoise2);
  FreeAndNil(nnoise3);

  FreeAndNil(wnoise1);
  FreeAndNil(wnoise2);
  FreeAndNil(wnoise3);

  FreeAndNil(noise1);
  FreeAndNil(noise2);
end;

procedure createSkyMap(const w, h: integer; var map, data: TByteArray);
var
  noise1, noise2: TLevelGen;
  x, y, i: integer;
  val, xd, yd, dist: single;
  count: integer;
begin
  noise1 := TLevelGen.create(w, h, 8);
  noise2 := TLevelGen.create(w, h, 8);

  for y := 0 to h - 1 do
  begin
    for x := 0 to w - 1 do
    begin
      i := x + y * w;

      val := abs(noise1.values[i] - noise2.values[i]) * 3 - 2;

      xd := x / (w - 1.0) * 2 - 1;
      yd := y / (h - 1.0) * 2 - 1;
      if (xd < 0) then
        xd := -xd;
      if (yd < 0) then
        yd := -yd;
      if xd >= yd then
        dist := xd
      else
        dist := yd;
      dist := dist * dist * dist * dist;
      dist := dist * dist * dist * dist;
      val := -val * 1 - 2.2;
      val := val + 1 - dist * 20;

      if (val < -0.25) then
        map[i] := Resources.infiniteFall.id
      else
        map[i] := Resources.cloud.id;
    end;
  end;

  for i := 0 to (w * h div 50) - 1 do
  begin
    x := random(w - 2) + 1;
    y := random(h - 2) + 1;
    if FindInMap(x, y, w, map, Resources.cloud) then
      map[x + y * w] := Resources.cloudCactus.id;
  end;

  count := 0;

  for i := 0 to w * h - 1 do
  begin
    x := random(w - 2) + 1;
    y := random(h - 2) + 1;
    if FindInMap(x, y, w, map, Resources.cloud) then
    begin
      map[x + y * w] := Resources.stairsDown.id;
      inc(count);
    end;
    if (count = 2) then
      break;
  end;

  FreeAndNil(noise1);
  FreeAndNil(noise2);
end;

procedure createAndValidateSkyMap(const w, h: integer;
  var map, data: TByteArray);
var
  count: array [0 .. 255] of integer;
  clouds, stairs, i: integer;
begin
  Setlength(map, w * h);
  Setlength(data, w * h);

  repeat
    createSkyMap(w, h, map, data);

    fillchar(count, sizeof(count), 0);
    for i := 0 to (w * h) - 1 do
      inc(count[map[i] and $FF]);

    clouds := count[Resources.cloud.id and $FF];
    stairs := count[Resources.stairsDown.id and $FF];
  until (clouds >= 2000) and (stairs >= 2);
end;

procedure createAndValidateUndergroundMap(const w, h, depth: integer;
  var map, data: TByteArray);
var
  count: array [0 .. 255] of integer;
  i: integer;
  rocks, dirt, ironOre, stairs: integer;
  enoughstairs: Boolean;
begin
  Setlength(map, w * h);
  Setlength(data, w * h);

  repeat
    createUndergroundMap(w, h, depth, map, data);

    fillchar(count, sizeof(count), 0);
    for i := 0 to w * h - 1 do
      inc(count[map[i] and $FF]);

    rocks := count[Resources.rock.id and $FF];
    dirt := count[Resources.dirt.id and $FF];
    ironOre := count[(Resources.ironOre.id and $FF) + depth - 1];
    stairs := count[Resources.stairsDown.id and $FF];
    if (depth < 3) then
      enoughstairs := stairs >= 2
    else
      enoughstairs := true;
  until (rocks >= 100) and (dirt >= 100) and (ironOre >= 20) and (enoughstairs);
end;

procedure createAndValidateTopMap(const w, h: integer;
  var map, data: TByteArray);
var
  count: array [0 .. 255] of integer;
  i: integer;
begin
  Setlength(map, w * h);
  Setlength(data, w * h);

  repeat
    createTopMap(w, h, map, data);

    fillchar(count, sizeof(count), 0);
    for i := 0 to w * h - 1 do
      inc(count[map[i] and $FF]);

  until (count[Resources.rock.id and $FF] >= 100) and
    (count[Resources.sand.id and $FF] >= 100) and
    (count[Resources.grass.id and $FF] >= 100) and
    (count[Resources.tree.id and $FF] >= 100) and
    (count[Resources.stairsDown.id and $FF] >= 2);
end;

{ TLevel }

constructor TLevel.create(const w, h, level: integer; parentLevel: TLevel);
var
  i, y, x: integer;
  aw: TAirwizard;
begin
  monsterDensity := 8;
  entities := TEntityList.create;

  dayFog := 0;
  grasscolor := 141;
  dirtcolor := 322;
  sandcolor := 550;

  if (level < 0) then
    dirtcolor := 222;

  depth := level;
  self.w := w;
  self.h := h;

  if (level = 1) then
    dirtcolor := 444;
  if (level = 0) then
  begin
    createAndValidateTopMap(w, h, map, data)
  end
  else if (level < 0) then
  begin
    createAndValidateUndergroundMap(w, h, -level, map, data);
    monsterDensity := 4;
  end
  else
  begin
    createAndValidateSkyMap(w, h, map, data); // Sky level
    monsterDensity := 4;
  end;
  if (parentLevel <> nil) then
  begin
    for y := 0 to h - 1 do
      for x := 0 to w - 1 do
      begin
        if (parentLevel.getTile(x, y) = Resources.stairsDown) then
        begin
          setTile(x, y, Resources.stairsUp, 0);
          if (level = 0) then
          begin
            setTile(x - 1, y, Resources.hardRock, 0);
            setTile(x + 1, y, Resources.hardRock, 0);
            setTile(x, y - 1, Resources.hardRock, 0);
            setTile(x, y + 1, Resources.hardRock, 0);
            setTile(x - 1, y - 1, Resources.hardRock, 0);
            setTile(x - 1, y + 1, Resources.hardRock, 0);
            setTile(x + 1, y - 1, Resources.hardRock, 0);
            setTile(x + 1, y + 1, Resources.hardRock, 0);
          end
          else
          begin
            setTile(x - 1, y, Resources.dirt, 0);
            setTile(x + 1, y, Resources.dirt, 0);
            setTile(x, y - 1, Resources.dirt, 0);
            setTile(x, y + 1, Resources.dirt, 0);
            setTile(x - 1, y - 1, Resources.dirt, 0);
            setTile(x - 1, y + 1, Resources.dirt, 0);
            setTile(x + 1, y - 1, Resources.dirt, 0);
            setTile(x + 1, y + 1, Resources.dirt, 0);
          end;
        end;
      end;
  end;
  Setlength(entitiesInTiles, w * h);
  for i := 0 to w * h - 1 do
    entitiesInTiles[i] := TEntityList.create;
  if (level = 1) then
  begin
    aw := TAirwizard.create;
    aw.x := w * 8;
    aw.y := h * 8;
    add(aw);
  end;
end;

destructor TLevel.Destroy;
var
  i: integer;
  Obj: TObject;
begin
  try
    for i := 0 to high(entitiesInTiles) do
      FreeAndNil(entitiesInTiles[i]);
    for i := 0 to entities.count - 1 do
    begin
      Obj := entities[i];
      FreeAndNil(Obj);
    end;
  except
  end;
  Setlength(entitiesInTiles, 0);
  FreeAndNil(entities);

  Setlength(map, 0);
  Setlength(data, 0);

  inherited;
end;

procedure TLevel.renderBackground(screen: TScreen;
  const xScroll, yScroll: integer);
var
  x, y, xo, yo, w, h: integer;
begin
  xo := xScroll shr 4;
  yo := yScroll shr 4;
  w := (screen.w + 15) shr 4;
  h := (screen.h + 15) shr 4;
  screen.setOffset(xScroll, yScroll);
  for y := yo to h + yo do
    for x := xo to w + xo do
      getTile(x, y).render(screen, self, x, y);
  screen.setOffset(0, 0);
end;

procedure TLevel.renderLight(screen: TScreen; xScroll, yScroll: integer);
var
  xo, yo, w, h: integer;
  i, r, x, y: integer;
  lr: integer;
  entities: TEntityList;
  e: TEntity;
begin
  xo := xScroll shr 4;
  yo := yScroll shr 4;
  w := (screen.w + 15) shr 4;
  h := (screen.h + 15) shr 4;

  screen.setOffset(xScroll, yScroll);
  r := 4;
  for y := yo - r to h + yo + r do
  begin
    for x := xo - r to w + xo + r do
    begin
      if (x < 0) or (y < 0) or (x >= self.w) or (y >= self.h) then
        continue;
      entities := entitiesInTiles[x + y * self.w];
      for i := 0 to entities.count - 1 do
      begin
        e := entities[i];
        lr := e.getLightRadius;
        if (lr > 0) then
          screen.renderLight(e.x - 1, e.y - 4, lr * 8);
      end;
      lr := getTile(x, y).getLightRadius(self, x, y);
      if (lr > 0) then
        screen.renderLight(x * 16 + 8, y * 16 + 8, lr * 8);
    end;
  end;
  screen.setOffset(0, 0);
end;

function TLevel.getTile(const x, y: integer): TTile;
begin
  if (x < 0) or (y < 0) or (x >= w) or (y >= h) then
    Result := Resources.rock
  else
    Result := Resources.tile(map[x + y * w]);
end;

procedure TLevel.setTile(const x, y: integer; const t: TTile;
  const dataVal: integer);
begin
  if (x < 0) or (y < 0) or (x >= w) or (y >= h) then
    exit;
  map[x + y * w] := t.id;
  data[x + y * w] := dataVal;
end;

function TLevel.getData(const x, y: integer): integer;
begin
  if (x < 0) or (y < 0) or (x >= w) or (y >= h) then
    Result := 0
  else
    Result := data[x + y * w] and $FF;
end;

procedure TLevel.setData(const x, y, val: integer);
begin
  if (x < 0) or (y < 0) or (x >= w) or (y >= h) then
    exit;
  data[x + y * w] := Byte(val);
end;

procedure TLevel.add(entity: TEntity);
begin
  if entity is TPlayer then
    player := TPlayer(entity);

  entity.removed := false;
  entities.add(entity);
  entity.init(self);

  insertEntity(entity.x shr 4, entity.y shr 4, entity);
end;

procedure TLevel.remove(e: TEntity);
var
  xto, yto: integer;
begin
  entities.remove(e);
  xto := e.x shr 4;
  yto := e.y shr 4;
  removeEntity(xto, yto, e);
end;

procedure TLevel.insertEntity(x, y: integer; e: TEntity);
begin
  if (x < 0) or (y < 0) or (x >= w) or (y >= h) then
    exit;
  entitiesInTiles[x + y * w].add(e);
end;

procedure TLevel.removeEntity(x, y: integer; e: TEntity);
begin
  if (x < 0) or (y < 0) or (x >= w) or (y >= h) then
    exit;
  entitiesInTiles[x + y * w].remove(e);
end;

procedure TLevel.trySpawn(const count: integer);
var
  ent: TLivingEntity;
  i: integer;
  lvl, minLevel, maxLevel: integer;
begin
  for i := 0 to count - 1 do
  begin
    minLevel := 1;
    maxLevel := 1;
    if (depth < 0) then
      maxLevel := (-depth) + 1;

    if (depth > 0) then
    begin
      minLevel := 4;
      maxLevel := 4;
    end;

    lvl := random(maxLevel - minLevel + 1) + minLevel;
    case random(5) of
      1:
        ent := TZombie.create(lvl);
      { 2:
        ent := TWanderer.create(lvl);
      }
    else
      ent := TSlime.create(lvl);
    end;

    if (ent.findStartPos(self)) then
      add(ent)
    else
      FreeAndNil(ent);
  end;
end;

procedure TLevel.Tick();
var
  i, xt, yt, xto, yto: integer;
  e: TEntity;
  dayFog: integer;
begin
  trySpawn(1);

  for i := 0 to (w * h div 50) - 1 do
  begin
    xt := random(w);
    yt := random(w);
    getTile(xt, yt).Tick(self, xt, yt);
  end;
  i := 0;

  // -----------------------------------------------------------------------------
  if (player <> nil) and (depth >= 0) then
  begin
    // above ground, day and night cycles
    dayFog := Trunc((cos(player.game.GetDayCycle() * 2 * PI) * MAX_FOG) +
      MAX_FOG) div 2;
    if (dayFog > 15) then
    begin
      grasscolor := 121;
      dirtcolor := 211;
      sandcolor := 330;
    end
    else if (dayFog > 8) then
    begin
      grasscolor := 131;
      dirtcolor := 322;
      sandcolor := 440;
    end
    else
    begin
      grasscolor := 141;
      dirtcolor := 322;
      sandcolor := 550;
    end;
  end
  else
  begin
    // underground, full darkness
    dayFog := Trunc(MAX_FOG * 3.5);
  end;
  monsterDensity := 6 * MAX_FOG div (dayFog + 1);
  // -----------------------------------------------------------------------------

  while i < entities.count do
  begin
    e := entities[i];
    xto := e.x shr 4;
    yto := e.y shr 4;

    e.Tick();

    if (e.removed) then
    begin
      entities.Delete(i);
      dec(i);
      removeEntity(xto, yto, e);
{$IFNDEF NEXTGEN}
      if (e is TParticle) then
{$ENDIF}
        FreeAndNil(e);
    end
    else
    begin
      xt := e.x shr 4;
      yt := e.y shr 4;

      if (xto <> xt) or (yto <> yt) then
      begin
        removeEntity(xto, yto, e);
        insertEntity(xt, yt, e);
      end;
    end;
    inc(i);
  end;
end;

procedure TLevel.sortAndRender(screen: TScreen; List: TEntityList);
var
  i: integer;
begin
{$IFDEF XE5}
  List.Sort(TComparer<TEntity>.Construct(

    function(const e0, e1: TEntity): integer
    begin
      if (e1.y < e0.y) then
        Result := 1
      else if (e1.y > e0.y) then
        Result := -1
      else
        Result := 0;
    end));
{$ELSE}
  List.Sort(LevelSortCompare);
{$ENDIF}
  for i := 0 to List.count - 1 do
    TEntity(List[i]).render(screen);
end;

function TLevel.getEntities(x0, y0, x1, y1: integer): TEntityList;
var
  xt0, yt0, xt1, yt1: integer;
  x, y: integer;
  entities: TEntityList;
  i: integer;
  e: TEntity;
begin
  Result := TEntityList.create;
  xt0 := (x0 shr 4) - 1;
  yt0 := (y0 shr 4) - 1;
  xt1 := (x1 shr 4) + 1;
  yt1 := (y1 shr 4) + 1;
  for y := yt0 to yt1 do
    for x := xt0 to xt1 do
    begin
      if (x < 0) or (y < 0) or (x >= w) or (y >= h) then
        continue;
      entities := entitiesInTiles[x + y * self.w];
      for i := 0 to entities.count - 1 do
      begin
        e := entities[i];
        if (e.intersects(x0, y0, x1, y1)) then
          Result.add(e);
      end;
    end;
end;

procedure TLevel.renderSprites(screen: TScreen;
const xScroll, yScroll: integer);
var
  x, y, xo, yo, w, h: integer;
  i: integer;
  List: TEntityList;
  rowSprites: TEntityList;

begin
  xo := xScroll shr 4;
  yo := yScroll shr 4;
  w := (screen.w + 15) shr 4;
  h := (screen.h + 15) shr 4;
  rowSprites := TEntityList.create;
  try
    screen.setOffset(xScroll, yScroll);
    for y := yo to h + yo do
    begin
      for x := xo to w + xo do
      begin
        if (x < 0) or (y < 0) or (x >= self.w) or (y >= self.h) then
          continue;
        List := entitiesInTiles[x + y * self.w];
        for i := 0 to List.count - 1 do
          rowSprites.add(List[i]);
      end;
      if (rowSprites.count > 0) then
        sortAndRender(screen, rowSprites);

      rowSprites.clear();
    end;
    screen.setOffset(0, 0);
  finally
    FreeAndNil(rowSprites);
  end;
end;

procedure TLevel.renderFog(screen, light: TScreen;
const xScroll, yScroll: integer);
var
  visMax: integer;
  offs: integer;
  xo, yo, w, h: integer;
  px, py: integer;
  res: single;
  visibility: array [0 .. 1024] of integer;
  i, j: integer;
  edge, edgeMax: integer;
  maxStep: integer;
  maxStepModif, dist, dstX, dstY: single;
  progress, rayPower, rayFall: single;
  step: integer;
  newVis, curVis, curX, curY: integer;
  lightLevel: single;
  visBlock: integer;
  visBlockCoef, tileRayFall, lightBlock: single;
  vis, x, y, z, xr, yr, zx, zy: integer;
  color, visBlend, s, sx, sy: integer;

  function normalize(const vis, visMax: integer): integer;
  begin
    if (vis > visMax) then
      Result := visMax
    else if (vis < 0) then
      Result := 0
    else
      Result := vis;
  end;

begin
  screen.clear(CalcColor(999));
  screen.setOffset(xScroll, yScroll);

  visMax := 1000;

  // get sizes and positions (in tiles)
  xo := xScroll shr 4;
  yo := yScroll shr 4;
  w := (screen.w shr 4) + 1;
  h := (screen.h shr 4) + 1;

  // change to a rectangle to make better raytracing
  if (w > h) then
  begin
    yo := yo - (w - h) div 2;
    h := w;
  end
  else
  begin
    xo := xo - (h - w) div 2;
    w := h;
  end;

  px := ((xScroll) shr 4) + w div 2;
  py := yo + h div 2;

  // resolution of raytracing
  res := 10;

  // prepare visibility grid
  try
    fillchar(visibility, sizeof(visibility), 0);

    // for every point on the edge of the screen
    edgeMax := Trunc((w + h) * 2 * res);
    for edge := 0 to edgeMax - 1 do
    begin
      // determine the destination point (we do a loop)
      if (edge < w * res) then
      begin
        dstX := edge;
        dstY := 0;
      end
      else if (edge < (w + h) * res) then
      begin
        dstX := (w * res);
        dstY := ((edge - (w * res)));
      end
      else if (edge < (w + w + h) * res) then
      begin
        dstX := (edge - (w + h) * res);
        dstY := (h * res);
      end
      else
      begin
        dstX := 0;
        dstY := (edgeMax - edge);
      end;

      // determine the ray properties
      dist := sqrt(power(xo + dstX / res - px, 2) +
        power(yo + dstY / res - py, 2));
      maxStepModif := 11;
      maxStep := Round(dist * maxStepModif);
      rayPower := (visMax);
      rayFall := (rayPower / (dist * maxStepModif * 0.1));

      // perform step-calculations on the line |Player --> destination|
      for step := 0 to maxStep do
      begin
        progress := step / maxStep;
        curX := px + Trunc(((xo + dstX / res) - px) * progress);
        curY := py + Trunc(((yo + dstY / res) - py) * progress);

        if (curY - yo >= 0) and (curX - xo >= 0) then
        begin
          // compute new visibility
          offs := (curY - yo) * w + curX - xo;
          curVis := visibility[offs];

          lightLevel := 0.5 * light.GetPixel(curX shl 4 - xScroll,
            curY shl 4 - yScroll);
          newVis := Round(curVis + rayPower);

          if (curVis < newVis) then
            visibility[offs] := newVis;

          // lower the strength of the ray if this tile is blocking the view
          visBlock := getTile(curX, curY).getVisibilityBlocking(self, curX,
            curY, player);
          visBlockCoef := (visBlock / 100.0);
          tileRayFall := (rayFall * visBlockCoef);
          lightBlock := (dayFog / maxStepModif * res) - (lightLevel);
          if (lightBlock < 0) then
            lightBlock := 0;

          rayPower := rayPower - (tileRayFall + lightBlock);
          if (rayPower <= 0) then
          begin
            // this ray is dead, but we must keep it because of light
            break;
          end;
        end
      end;
    end;

    // render blocks of fog (8x8)
    for y := 0 to h do
    begin
      offs := y * w;
      for x := 0 to w do
      begin
        vis := normalize(visibility[offs + x], visMax);

        xr := (xo + x) * 16;
        yr := (yo + y) * 16;
        for z := 0 to 3 do
        begin
          zx := (z mod 2);
          zy := (z div 2);
          visBlend := vis;
          // blend levels
          for s := 0 to 3 do
          begin
            sx := (s mod 2) - 1;
            sy := (s div 2) - 1;
            if (y + sy + zy < 0) or (y + sy + zy >= h) or (x + sx + zx < 0) or
              (x + sx + zx >= w) then
            begin
              visBlend := visBlend + vis;
            end
            else
            begin
              visBlend := visBlend +
                normalize(visibility[(y + sy + zy) * w + x + sx + zx], visMax);
            end;
          end;
          visBlend := visBlend div 5;
          // create normal color for overlay
          color := visBlend div 6;
          // render one 8x8 patch
          screen.renderPoint(xr + zx * 8, yr + zy * 8, 8, color);
        end;
      end;
    end;
  finally
  end;
  screen.setOffset(0, 0);
end;

// -----------------------------------------------------------------------------
{ TResource }

constructor TResource.create(const name: string; const sprite: integer;
const color: Cardinal);
begin
  self.name := name;
  self.sprite := sprite;
  self.color := color;
end;

function TResource.interactOn(tile: TTile; level: TLevel; xt, yt: integer;
player: TPlayer; attackDir: integer): Boolean;

const
  csparkChars: Array [0 .. 4] of Char = ('.', ',', '-', '+', 'x');

var
  sameTile: Boolean;
  t, tl, tr, tu, td: TTile;
  l, r, u, d: Boolean;
  i, sparks: integer;
begin
  Result := false;
  sameTile := (xt = (player.x shr 4)) and (yt = (player.y shr 4));

  if self = Resources.res_wood then
  begin
    // build wooden wall on dirt and grass
    if (tile = Resources.dirt) or (tile = Resources.grass) and (not sameTile)
    then
    begin
      level.setTile(xt, yt, Resources.woodenWall, 0);
      Result := true;
      exit;
    end;
  end;

  if self = Resources.res_stone then
  begin
    // build rock wall on dirt and grass
    if (tile = Resources.dirt) or (tile = Resources.grass) and (not sameTile)
    then
    begin
      level.setTile(xt, yt, Resources.rockWall, 0);
      Result := true;
      exit;
    end;
  end;

  if self = Resources.res_plank then
  begin
    // build fence on dirt and grass
    if (tile = Resources.dirt) or (tile = Resources.grass) and (not sameTile)
    then
    begin
      level.setTile(xt, yt, Resources.fence, 0);
      Result := true;
      exit;
    end;
  end;

  if self = Resources.res_stoneTile then
  begin
    // build paved road on dirt and grass
    if (tile = Resources.dirt) or (tile = Resources.grass) and (not sameTile)
    then
    begin
      level.setTile(xt, yt, Resources.rockFloor, 0);
      Result := true;
      exit;
    end;
  end;

  if (self = Resources.res_door) or (self = Resources.res_window) then
  begin
    // check for a frame
    tl := level.getTile(xt - 1, yt);
    tr := level.getTile(xt + 1, yt);
    tu := level.getTile(xt, yt - 1);
    td := level.getTile(xt, yt + 1);

    l := (xt > 0) and ((tl = Resources.rockWall) or (tl = Resources.woodenWall)
      or (tl = Resources.rock) or (tl = Resources.door) or
      (tl = Resources.window));
    r := (xt < level.w) and ((tr = Resources.rockWall) or
      (tr = Resources.woodenWall) or (tr = Resources.rock) or
      (tr = Resources.door) or (tr = Resources.window));
    u := (yt > 0) and ((tu = Resources.rockWall) or (tu = Resources.woodenWall)
      or (tu = Resources.rock) or (tu = Resources.door) or
      (tu = Resources.window));
    d := (yt < level.h) and ((td = Resources.rockWall) or
      (td = Resources.woodenWall) or (td = Resources.rock) or
      (td = Resources.door) or (td = Resources.window));

    if (l and r) or (u and d) then
    begin
      // build door on dirt and grass
      if ((tile = Resources.dirt) or (tile = Resources.grass)) and (not sameTile)
      then
      begin
        if self = Resources.res_door then
          t := Resources.door
        else
          t := Resources.window;
        level.setTile(xt, yt, t, 0);
        Result := true;
        exit;
      end;
    end;
  end;
  if (self = Resources.res_torch) then
  begin
    // place torch on dirt and grass and stone floor and sand
    if ((tile = Resources.dirt) or (tile = Resources.grass) or
      (tile = Resources.rockFloor) or (tile = Resources.flower) or
      (tile = Resources.sand)) and (not sameTile) then
    begin
      level.add(TTorch.create(player, (xt shl 4) + 8, (yt shl 4) + 8));
      Result := true;
      exit;
    end;
  end;

  if (self = Resources.res_flint) then
  begin
    // put a pile of wood (wall) on fire (maybe)
    if (tile = Resources.woodenWall) and (not sameTile) then
    begin
      // make sparks
      sparks := random(5) + 2;
      for i := 0 to sparks - 1 do
      begin
        level.add(TTextParticle.create(csparkChars[random(high(csparkChars))],
          (xt shl 4) + 8, (yt shl 4) + 8, CalcColor(-1, 554, 554, 554)));
      end;
      // try to light it
      if (random(8) = 0) then
        level.add(TFire.create(player, (xt shl 4) + 8, (yt shl 4) + 8, 1, 100));

      // randomly loose the item
      if (random(5) = 0) then
      begin
        Result := true;
        exit;
      end;
    end;
  end;
end;

{ TPlantableResource }

constructor TPlantableResource.create(name: string; sprite: integer;
color: Cardinal; targetTile: TTile; Source: array of TTile);
var
  i: integer;
begin
  inherited create(name, sprite, color);
  sourceTiles := TTileList.create;
  self.targetTile := targetTile;
  for i := low(Source) to high(Source) do
    sourceTiles.add(Source[i]);
end;

destructor TPlantableResource.Destroy;
begin
  FreeAndNil(sourceTiles);
  inherited;
end;

function TPlantableResource.interactOn(tile: TTile; level: TLevel;
xt, yt: integer; player: TPlayer; attackDir: integer): Boolean;
var
  i: integer;
begin
  Result := false;
  for i := 0 to sourceTiles.count - 1 do
    if sourceTiles[i] = tile then
    begin
      level.setTile(xt, yt, targetTile, 0);
      Result := true;
      exit;
    end;
end;

{ TFoodResource }

constructor TFoodResource.create(name: string; sprite: integer; color: Cardinal;
heal, staminaCost: integer);
begin
  inherited create(name, sprite, color);
  self.heal := heal;
  self.staminaCost := staminaCost;
end;

function TFoodResource.interactOn(tile: TTile; level: TLevel; xt, yt: integer;
player: TPlayer; attackDir: integer): Boolean;
begin
  if (player.health < player.maxHealth) and (player.payStamina(staminaCost))
  then
  begin
    player.heal(heal);
    Result := true;
  end
  else
    Result := false;
end;

{ TResources }

constructor TResources.create;
begin
  grass := TGrassTile.create(0);
  rock := TRockTile.create(1);
  water := TWaterTile.create(2);
  flower := TFlowerTile.create(3);
  tree := TTreeTile.create(4);
  dirt := TDirtTile.create(5);
  sand := TSandTile.create(6);
  cactus := TCactusTile.create(7);
  hole := THoleTile.create(8);
  treeSapling := TSaplingTile.create(9, grass, tree);
  cactusSapling := TSaplingTile.create(10, sand, cactus);
  farmland := TFarmTile.create(11);
  wheat := TWheatTile.create(12);
  lava := TLavaTile.create(13);
  stairsDown := TStairsTile.create(14, false);
  stairsUp := TStairsTile.create(15, true);
  infiniteFall := TInfiniteFallTile.create(16);
  cloud := TCloudTile.create(17);

  res_wood := TResource.create('Wood', 1 + 4 * 32,
    CalcColor(-1, 200, 531, 430));
  res_stone := TResource.create('Stone', 2 + 4 * 32,
    CalcColor(-1, 111, 333, 555));

  res_flower := TPlantableResource.create('Flower', 0 + 4 * 32,
    CalcColor(-1, 10, 444, 330), flower, grass);
  res_acorn := TPlantableResource.create('Acorn', 3 + 4 * 32,
    CalcColor(-1, 100, 531, 320), treeSapling, grass);
  res_dirt := TPlantableResource.create('Dirt', 2 + 4 * 32,
    CalcColor(-1, 100, 322, 432), dirt, [hole, water, lava]);
  res_sand := TPlantableResource.create('Sand', 2 + 4 * 32,
    CalcColor(-1, 110, 440, 550), sand, [grass, dirt]);
  res_cactusFlower := TPlantableResource.create('Cactus', 4 + 4 * 32,
    CalcColor(-1, 10, 40, 50), cactusSapling, sand);
  res_seeds := TPlantableResource.create('Seeds', 5 + 4 * 32,
    CalcColor(-1, 10, 40, 50), wheat, [farmland]);

  res_wheat := TResource.create('Wheat', 6 + 4 * 32,
    CalcColor(-1, 110, 330, 550));
  res_bread := TFoodResource.create('Bread', 8 + 4 * 32,
    CalcColor(-1, 110, 330, 550), 2, 5);
  res_apple := TFoodResource.create('Apple', 9 + 4 * 32,
    CalcColor(-1, 100, 300, 500), 1, 5);

  res_coal := TResource.create('COAL', 10 + 4 * 32,
    CalcColor(-1, 000, 111, 111));
  res_ironOre := TResource.create('I.ORE', 10 + 4 * 32,
    CalcColor(-1, 100, 322, 544));
  res_goldOre := TResource.create('G.ORE', 10 + 4 * 32,
    CalcColor(-1, 110, 440, 553));
  res_ironIngot := TResource.create('IRON', 11 + 4 * 32,
    CalcColor(-1, 100, 322, 544));
  res_goldIngot := TResource.create('GOLD', 11 + 4 * 32,
    CalcColor(-1, 110, 330, 553));

  res_slime := TResource.create('SLIME', 10 + 4 * 32,
    CalcColor(-1, 10, 30, 50));
  res_glass := TResource.create('glass', 12 + 4 * 32,
    CalcColor(-1, 555, 555, 555));
  res_cloth := TResource.create('cloth', 1 + 4 * 32,
    CalcColor(-1, 25, 252, 141));
  res_cloud := TPlantableResource.create('cloud', 2 + 4 * 32,
    CalcColor(-1, 222, 555, 444), cloud, [infiniteFall]);
  res_gem := TResource.create('gem', 13 + 4 * 32, CalcColor(-1, 101, 404, 545));

  res_plank := TResource.create('Plank', 1 + 4 * 32,
    CalcColor(-1, 200, 531, 430));
  res_stoneTile := TResource.create('tile', 1 + 4 * 32,
    CalcColor(-1, 222, 555, 444));
  res_door := TResource.create('door', 6 + 10 * 32,
    CalcColor(-1, 300, 522, 532));
  res_window := TResource.create('window', 6 + 10 * 32,
    CalcColor(-1, 224, 225, 224));
  res_torch := TResource.create('torch', 7 + 10 * 32,
    CalcColor(-1, 200, 441, 554));
  res_flint := TResource.create('Flint', 2 + 4 * 32,
    CalcColor(-1, 111, 222, 333));
  res_bottle := TResource.create('Bottle', 14 + 4 * 32,
    CalcColor(-1, 225, -1, 335));
  // res_ale := TFoodResource.create('Ale', 14 + 4 * 32,
  // CalcColor(-1, 421, 521, 335), 5, 8);

  hardRock := THardRockTile.create(18);
  ironOre := TOreTile.create(19, res_ironOre);
  goldOre := TOreTile.create(20, res_goldOre);
  gemOre := TOreTile.create(21, res_gem);
  cloudCactus := TCloudCactusTile.create(22);

  woodenWall := TWoodenWallTile.create(100);
  rockWall := TRockWallTile.create(101);
  fence := TFenceTile.create(102);
  rockFloor := TRockFloorTile.create(103);

  door := TDoorTile.create(104, dirt);
  window := TWindowTile.create(105, dirt);
end;

function TResources.tile(id: integer): TTile;
begin
  if grass.id = id then
    Result := grass
  else if rock.id = id then
    Result := rock
  else if water.id = id then
    Result := water
  else if flower.id = id then
    Result := flower
  else if tree.id = id then
    Result := tree
  else if dirt.id = id then
    Result := dirt
  else if sand.id = id then
    Result := sand
  else if cactus.id = id then
    Result := cactus
  else if hole.id = id then
    Result := hole
  else if treeSapling.id = id then
    Result := treeSapling
  else if cactusSapling.id = id then
    Result := cactusSapling
  else if farmland.id = id then
    Result := farmland
  else if wheat.id = id then
    Result := wheat
  else if lava.id = id then
    Result := lava
  else if stairsDown.id = id then
    Result := stairsDown
  else if stairsUp.id = id then
    Result := stairsUp
  else if infiniteFall.id = id then
    Result := infiniteFall
  else if cloud.id = id then
    Result := cloud
  else if hardRock.id = id then
    Result := hardRock
  else if ironOre.id = id then
    Result := ironOre
  else if goldOre.id = id then
    Result := goldOre
  else if gemOre.id = id then
    Result := gemOre
  else if cloudCactus.id = id then
    Result := cloudCactus
  else if woodenWall.id = id then
    Result := woodenWall
  else if rockWall.id = id then
    Result := rockWall
  else if fence.id = id then
    Result := fence
  else if rockFloor.id = id then
    Result := rockFloor
  else if door.id = id then
    Result := door
  else if window.id = id then
    Result := window
  else
    Result := grass;
end;

destructor TResources.Destroy;
begin
  FreeAndNil(res_wood);
  FreeAndNil(res_stone);
  FreeAndNil(res_flower);
  FreeAndNil(res_acorn);
  FreeAndNil(res_dirt);
  FreeAndNil(res_sand);
  FreeAndNil(res_cactusFlower);
  FreeAndNil(res_seeds);
  FreeAndNil(res_wheat);
  FreeAndNil(res_bread);
  FreeAndNil(res_apple);

  FreeAndNil(res_coal);
  FreeAndNil(res_ironOre);
  FreeAndNil(res_goldOre);
  FreeAndNil(res_ironIngot);
  FreeAndNil(res_goldIngot);

  FreeAndNil(res_slime);
  FreeAndNil(res_glass);
  FreeAndNil(res_cloth);
  FreeAndNil(res_cloud);
  FreeAndNil(res_gem);

  FreeAndNil(res_plank);
  FreeAndNil(res_stoneTile);
  FreeAndNil(res_door);
  FreeAndNil(res_window);
  FreeAndNil(res_torch);
  FreeAndNil(res_flint);
  FreeAndNil(res_bottle);
  // FreeAndNil(res_ale);

  FreeAndNil(grass);
  FreeAndNil(rock);
  FreeAndNil(water);
  FreeAndNil(flower);
  FreeAndNil(tree);
  FreeAndNil(dirt);
  FreeAndNil(sand);
  FreeAndNil(cactus);
  FreeAndNil(hole);
  FreeAndNil(treeSapling);
  FreeAndNil(cactusSapling);
  FreeAndNil(farmland);
  FreeAndNil(wheat);
  FreeAndNil(lava);
  FreeAndNil(stairsDown);
  FreeAndNil(stairsUp);
  FreeAndNil(infiniteFall);
  FreeAndNil(cloud);
  FreeAndNil(hardRock);
  FreeAndNil(ironOre);
  FreeAndNil(goldOre);
  FreeAndNil(gemOre);
  FreeAndNil(cloudCactus);
  FreeAndNil(woodenWall);
  FreeAndNil(rockWall);
  FreeAndNil(fence);
  FreeAndNil(rockFloor);
  FreeAndNil(door);
  FreeAndNil(window);

  inherited;
end;

{ TToolType }

constructor TToolType.create(name: string; sprite: integer);
begin
  self.name := name;
  self.sprite := sprite;
end;

{ TToolTypes }

constructor TToolTypes.create;
begin
  shovel := TToolType.create('Shvl', 0);
  hoe := TToolType.create('Hoe', 1);
  sword := TToolType.create('Swrd', 2);
  pickaxe := TToolType.create('Pick', 3);
  axe := TToolType.create('Axe', 4);
end;

destructor TToolTypes.Destroy;
begin
  FreeAndNil(shovel);
  FreeAndNil(hoe);
  FreeAndNil(sword);
  FreeAndNil(pickaxe);
  FreeAndNil(axe);
  inherited;
end;

{ TItem }

function TItem.getColor: Cardinal;
begin
  Result := 0;
end;

function TItem.getSprite: integer;
begin
  Result := 0;
end;

procedure TItem.onTake(entity: TItemEntity);
begin
end;

procedure TItem.renderInventory(const screen: TScreen; x, y: integer);
begin
end;

function TItem.interact(player: TPlayer; entity: TEntity;
attackDir: integer): Boolean;
begin
  Result := false;
end;

function TItem.interactOn(const tile: TTile; const level: TLevel;
const xt, yt: integer; const player: TPlayer; const attackDir: integer)
  : Boolean;
begin
  Result := false;
end;

procedure TItem.renderIcon(const screen: TScreen; const x, y: integer);
begin
end;

function TItem.isDepleted(): Boolean;
begin
  Result := false;
end;

function TItem.canAttack(): Boolean;
begin
  Result := false;
end;

function TItem.getAttackDamageBonus(const e: TEntity): integer;
begin
  Result := 0;
end;

function TItem.getName(): string;
begin
  Result := '';
end;

function TItem.matches(item: TItem): Boolean;
begin
  Result := item = self;
end;

// -----------------------------------------------------------------------------

{ TFurnitureItem }

constructor TFurnitureItem.create(const item: TFurniture);
begin
  inherited create;
  placed := false;
  Furniture := item;
end;

destructor TFurnitureItem.Destroy;
begin
  FreeAndNil(Furniture);
  inherited;
end;

procedure TFurnitureItem.renderIcon(const screen: TScreen; const x, y: integer);
begin
  screen.render(x, y, getSprite(), getColor(), 0);
end;

procedure TFurnitureItem.renderInventory(const screen: TScreen; x, y: integer);
begin
  screen.render(x, y, getSprite(), getColor(), 0);
  Font.draw(getName, screen, x + 8, y, CalcColor(-1, 555, 555, 555));
end;

procedure TFurnitureItem.onTake(entity: TItemEntity);
begin
end;

function TFurnitureItem.canAttack(): Boolean;
begin
  Result := false;
end;

function TFurnitureItem.interactOn(const tile: TTile; const level: TLevel;
const xt, yt: integer; const player: TPlayer; const attackDir: integer)
  : Boolean;
begin
  if (tile.mayPass(level, xt, yt, Furniture)) then
  begin
    Furniture.x := xt * 16 + 8;
    Furniture.y := yt * 16 + 8;
    level.add(Furniture);
    placed := true;
    Result := true;
  end
  else
    Result := false;
end;

function TFurnitureItem.isDepleted(): Boolean;
begin
  Result := placed;
end;

function TFurnitureItem.getColor: Cardinal;
begin
  Result := Furniture.col;
end;

function TFurnitureItem.getSprite(): integer;
begin
  Result := Furniture.sprite + 10 * 32;
end;

function TFurnitureItem.getName(): string;
begin
  Result := Furniture.name;
end;

{ TPowerGloveItem }

function TPowerGloveItem.getColor: Cardinal;
begin
  Result := CalcColor(-1, 100, 320, 430);
end;

function TPowerGloveItem.getSprite: integer;
begin
  Result := 7 + 4 * 32;
end;

procedure TPowerGloveItem.renderIcon(const screen: TScreen;
const x, y: integer);
begin
  screen.render(x, y, getSprite, getColor, 0);
end;

procedure TPowerGloveItem.renderInventory(const screen: TScreen; x, y: integer);
begin
  screen.render(x, y, getSprite(), getColor(), 0);
  Font.draw(getName(), screen, x + 8, y, CalcColor(-1, 555, 555, 555));
end;

function TPowerGloveItem.getName(): string;
begin
  Result := 'Pow glove';
end;

function TPowerGloveItem.interact(player: TPlayer; entity: TEntity;
attackDir: integer): Boolean;
var
  f: TFurniture;
begin
  if (entity is TFurniture) then
  begin
    f := entity as TFurniture;
    f.take(player);
    Result := true;
  end
  else
    Result := false;
end;

{ TResourceItem }

constructor TResourceItem.create(const item: TResource);
begin
  Resource := item;
  count := 1;
end;

constructor TResourceItem.create(const item: TResource; count: integer);
begin
  Resource := item;
  self.count := count;
end;

function TResourceItem.getColor: Cardinal;
begin
  Result := (Resource as TResource).color;
end;

function TResourceItem.getSprite(): integer;
begin
  Result := Resource.sprite;
end;

procedure TResourceItem.renderIcon(const screen: TScreen; const x, y: integer);
begin
  screen.render(x, y, Resource.sprite, Resource.color, 0);
end;

procedure TResourceItem.renderInventory(const screen: TScreen; x, y: integer);
var
  cc: integer;
begin
  screen.render(x, y, Resource.sprite, Resource.color, 0);
  Font.draw(Resource.name, screen, x + 32, y, CalcColor(-1, 555, 555, 555));
  cc := count;
  if (cc > 999) then
    cc := 999;
  Font.draw(inttostr(cc), screen, x + 8, y, CalcColor(-1, 444, 444, 444));
end;

function TResourceItem.getName(): string;
begin
  Result := Resource.name;
end;

procedure TResourceItem.onTake(entity: TItemEntity);
begin
end;

function TResourceItem.interactOn(const tile: TTile; const level: TLevel;
const xt, yt: integer; const player: TPlayer; const attackDir: integer)
  : Boolean;
begin
  if (Resource.interactOn(tile, level, xt, yt, player, attackDir)) then
  begin
    dec(count);
    Result := true;
  end
  else
    Result := false;
end;

function TResourceItem.isDepleted(): Boolean;
begin
  Result := count <= 0;
end;

{ TToolItem }

constructor TToolItem.create(typ: TToolType; level: integer);
begin
  self.typ := typ;
  self.level := level;

  names[0] := 'Wood';
  names[1] := 'Rock';
  names[2] := 'Iron';
  names[3] := 'Gold';
  names[4] := 'Gem';

  colors[0] := CalcColor(-1, 100, 321, 431);
  colors[1] := CalcColor(-1, 100, 321, 111);
  colors[2] := CalcColor(-1, 100, 321, 555);
  colors[3] := CalcColor(-1, 100, 321, 550);
  colors[4] := CalcColor(-1, 100, 321, 055);
end;

destructor TToolItem.Destroy;
begin
  inherited;
end;

function TToolItem.getColor: Cardinal;
begin
  Result := colors[level];
end;

function TToolItem.getSprite: integer;
begin
  Result := typ.sprite + 5 * 32;
end;

procedure TToolItem.renderIcon(const screen: TScreen; const x, y: integer);
begin
  screen.render(x, y, getSprite(), getColor(), 0);
end;

procedure TToolItem.renderInventory(const screen: TScreen; x, y: integer);
begin
  screen.render(x, y, getSprite(), getColor(), 0);
  Font.draw(getName(), screen, x + 8, y, CalcColor(-1, 555, 555, 555));
end;

function TToolItem.getName(): string;
begin
  Result := names[level] + ' ' + typ.name;
end;

procedure TToolItem.onTake(entity: TItemEntity);
begin
end;

function TToolItem.canAttack(): Boolean;
begin
  Result := true;
end;

function TToolItem.getAttackDamageBonus(const e: TEntity): integer;
begin
  if (typ = Tooltypes.axe) then
    Result := (level + 1) * 2 + random(4)
  else if (typ = Tooltypes.sword) then
    Result := (level + 1) * 3 + random(2 + level * level * 2)
  else
    Result := 1;
end;

function TToolItem.matches(item: TItem): Boolean;
var
  other: TToolItem;
begin
  if item is TToolItem then
  begin
    other := TToolItem(item);
    if (other.typ <> typ) then
      Result := false
    else if (other.level <> level) then
      Result := false
    else
      Result := true;
  end
  else
    Result := false;
end;

{ TTile }

constructor TTile.create(const TileId: integer);
begin
  inherited create();

  connectsToGrass := false;
  connectsToSand := false;
  connectsToLava := false;
  connectsToWater := false;
  connectsToPavement := false;

  id := TileId;
end;

procedure TTile.render(screen: TScreen; level: TLevel; x, y: integer);
begin
end;

function TTile.getLightRadius(level: TLevel; x, y: integer): integer;
begin
  Result := 0;
end;

procedure TTile.Tick(level: TLevel; xt, yt: integer);
begin
end;

function TTile.mayPass(level: TLevel; x, y: integer; e: TEntity): Boolean;
begin
  Result := true;
end;

procedure TTile.hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
dmg, attackDir: integer);
begin
end;

procedure TTile.hurt(level: TLevel; x, y, dmg: integer);
begin
end;

procedure TTile.bumpedInto(level: TLevel; xt, yt: integer; entity: TEntity);
begin
end;

procedure TTile.steppedOn(level: TLevel; xt, yt: integer; entity: TEntity);
begin
end;

function TTile.interact(level: TLevel; xt, yt: integer; player: TPlayer;
item: TItem; attackDir: integer): Boolean;
begin
  Result := false;
end;

function TTile.use(level: TLevel; xt, yt: integer; player: TPlayer;
attackDir: integer): Boolean;
begin
  Result := false;
end;

function TTile.connectsToLiquid(): Boolean;
begin
  Result := connectsToWater or connectsToLava;
end;

function TTile.getVisibilityBlocking(level: TLevel; x, y: integer;
e: TEntity): integer;
begin
  if mayPass(level, x, y, e) then
    Result := 0
  else
    Result := 100;
end;

function TTile.getFireFuelAmount(level: TLevel; xt, yt: integer): integer;
begin
  Result := 0;
end;

procedure TTile.burnFireFuel(level: TLevel; xt, yt, burnPower: integer;
ent: TEntity);
begin
end;

function TTile.isFlammable(level: TLevel; xt, yt: integer): Boolean;
begin
  Result := getFireFuelAmount(level, xt, yt) > 0;
end;

{ THardRockTile }

constructor THardRockTile.create(id: integer);
begin
  inherited create(id);
end;

procedure THardRockTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  col, transitionColor: Cardinal;
  u, d, l, r, ul, dl, ur, dr: Boolean;
  i, j: integer;
begin
  col := CalcColor(334, 334, 223, 223);
  transitionColor := CalcColor(001, 334, 445, level.dirtcolor);

  u := level.getTile(x, y - 1) <> self;
  d := level.getTile(x, y + 1) <> self;
  l := level.getTile(x - 1, y) <> self;
  r := level.getTile(x + 1, y) <> self;

  ul := level.getTile(x - 1, y - 1) <> self;
  dl := level.getTile(x - 1, y + 1) <> self;
  ur := level.getTile(x + 1, y - 1) <> self;
  dr := level.getTile(x + 1, y + 1) <> self;

  if (not u) and (not l) then
  begin
    if (not ul) then
      screen.render(x * 16 + 0, y * 16 + 0, 0, col, 0)
    else
      screen.render(x * 16 + 0, y * 16 + 0, 7 + 0 * 32, transitionColor, 3);
  end
  else
  begin
    if l then
      i := 6
    else
      i := 5;
    if u then
      j := 2
    else
      j := 1;
    screen.render(x * 16 + 0, y * 16 + 0, i + j * 32, transitionColor, 3);
  end;

  if (not u) and (not r) then
  begin
    if (not ur) then
      screen.render(x * 16 + 8, y * 16 + 0, 1, col, 0)
    else
      screen.render(x * 16 + 8, y * 16 + 0, 8 + 0 * 32, transitionColor, 3)
  end
  else
  begin
    if r then
      i := 4
    else
      i := 5;
    if u then
      j := 2
    else
      j := 1;
    screen.render(x * 16 + 8, y * 16 + 0, i + j * 32, transitionColor, 3);
  end;

  if (not d) and (not l) then
  begin
    if (not dl) then
      screen.render(x * 16 + 0, y * 16 + 8, 2, col, 0)
    else
      screen.render(x * 16 + 0, y * 16 + 8, 7 + 1 * 32, transitionColor, 3);
  end
  else
  begin
    if l then
      i := 6
    else
      i := 5;
    if d then
      j := 0
    else
      j := 1;
    screen.render(x * 16 + 0, y * 16 + 8, i + j * 32, transitionColor, 3);
  end;

  if (not d) and (not r) then
  begin
    if (not dr) then
      screen.render(x * 16 + 8, y * 16 + 8, 3, col, 0)
    else
      screen.render(x * 16 + 8, y * 16 + 8, 8 + 1 * 32, transitionColor, 3);
  end
  else
  begin
    if r then
      i := 4
    else
      i := 5;
    if d then
      j := 0
    else
      j := 1;
    screen.render(x * 16 + 8, y * 16 + 8, i + j * 32, transitionColor, 3);
  end;
end;

function THardRockTile.mayPass(level: TLevel; x, y: integer;
e: TEntity): Boolean;
begin
  Result := false;
end;

procedure THardRockTile.hurt(level: TLevel; x, y: integer;
Source: TLivingEntity; dmg, attackDir: integer);
begin
  hurt(level, x, y, 0);
end;

function THardRockTile.interact(level: TLevel; xt, yt: integer; player: TPlayer;
item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.pickaxe) and (Tool.level = 4) then
    begin
      if (player.payStamina(4 - Tool.level)) then
      begin
        hurt(level, xt, yt, random(10) + (Tool.level) * 5 + 10);
        Result := true;
        exit;
      end;
    end;
  end;
  Result := false;
end;

procedure THardRockTile.hurt(level: TLevel; x, y, dmg: integer);
var
  i, count, damage: integer;
begin
  damage := level.getData(x, y) + dmg;
  level.add(TSmashParticle.create(x * 16 + 8, y * 16 + 8));
  level.add(TTextParticle.create(inttostr(dmg), x * 16 + 8, y * 16 + 8,
    CalcColor(-1, 500, 500, 500)));
  if (damage >= 200) then
  begin
    count := random(4) + 1;
    for i := 0 to count - 1 do
    begin
      level.add(TItemEntity.create(TResourceItem.create(Resources.res_stone),
        x * 16 + random(10) + 3, y * 16 + random(10) + 3));
    end;
    count := random(2);
    for i := 0 to count - 1 do
    begin
      level.add(TItemEntity.create(TResourceItem.create(Resources.res_coal),
        x * 16 + random(10) + 3, y * 16 + random(10) + 3));
    end;
    level.setTile(x, y, Resources.dirt, 0);
  end
  else
  begin
    level.setData(x, y, damage);
  end;
end;

procedure THardRockTile.Tick(level: TLevel; xt, yt: integer);
var
  damage: integer;
begin
  damage := level.getData(xt, yt);
  if (damage > 0) then
    level.setData(xt, yt, damage - 1);
end;

{ TInfiniteFallTile }

procedure TInfiniteFallTile.render(screen: TScreen; level: TLevel;
x, y: integer);
begin
end;

procedure TInfiniteFallTile.Tick(level: TLevel; xt, yt: integer);
begin
end;

function TInfiniteFallTile.mayPass(level: TLevel; x, y: integer;
e: TEntity): Boolean;
begin
  Result := e is TAirwizard;
end;

{ TStairsTile }

constructor TStairsTile.create(id: integer; leadsUp: Boolean);
begin
  inherited create(id);
  self.leadsUp := leadsUp;
end;

procedure TStairsTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  xt: integer;
  color: Cardinal;
begin
  color := CalcColor(level.dirtcolor, 000, 333, 444);
  xt := 0;
  if (leadsUp) then
    xt := 2;
  screen.render(x * 16 + 0, y * 16 + 0, xt + 2 * 32, color, 0);
  screen.render(x * 16 + 8, y * 16 + 0, xt + 1 + 2 * 32, color, 0);
  screen.render(x * 16 + 0, y * 16 + 8, xt + 3 * 32, color, 0);
  screen.render(x * 16 + 8, y * 16 + 8, xt + 1 + 3 * 32, color, 0);
end;

{ TStoneTile }

procedure TStoneTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  rc1, rc2, rc3: integer;
begin
  rc1 := 111;
  rc2 := 333;
  rc3 := 555;
  screen.render(x * 16 + 0, y * 16 + 0, 32, CalcColor(rc1, level.dirtcolor,
    rc2, rc3), 0);
  screen.render(x * 16 + 8, y * 16 + 0, 32, CalcColor(rc1, level.dirtcolor,
    rc2, rc3), 0);
  screen.render(x * 16 + 0, y * 16 + 8, 32, CalcColor(rc1, level.dirtcolor,
    rc2, rc3), 0);
  screen.render(x * 16 + 8, y * 16 + 8, 32, CalcColor(rc1, level.dirtcolor,
    rc2, rc3), 0);
end;

function TStoneTile.mayPass(level: TLevel; x, y: integer; e: TEntity): Boolean;
begin
  Result := false;
end;

{ TSaplingTile }

constructor TSaplingTile.create(id: integer; onType, growsTo: TTile);
begin
  inherited create(id);
  self.growsTo := growsTo;
  self.onType := onType;

  connectsToSand := onType.connectsToSand;
  connectsToGrass := onType.connectsToGrass;
  connectsToWater := onType.connectsToWater;
  connectsToLava := onType.connectsToLava;
  connectsToPavement := onType.connectsToPavement;
end;

procedure TSaplingTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  col: Cardinal;
begin
  onType.render(screen, level, x, y);
  col := CalcColor(10, 40, 50, -1);
  screen.render(x * 16 + 4, y * 16 + 4, 11 + 3 * 32, col, 0);
end;

procedure TSaplingTile.Tick(level: TLevel; xt, yt: integer);
var
  age: integer;
begin
  age := level.getData(xt, yt) + 1;
  if (age > 100) then
    level.setTile(xt, yt, growsTo, 0)
  else
    level.setData(xt, yt, age);
end;

procedure TSaplingTile.hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
dmg, attackDir: integer);
begin
  level.setTile(x, y, onType, 0);
end;

function TSaplingTile.getFireFuelAmount(level: TLevel; xt: integer;
yt: integer): integer;
begin
  Result := 1;
end;

procedure TSaplingTile.burnFireFuel(level: TLevel; xt: integer; yt: integer;
burnPower: integer; ent: TEntity);
begin
  level.setTile(xt, yt, Resources.dirt, 0);
end;

{ TFarmTile }

procedure TFarmTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  col: Cardinal;
begin
  col := CalcColor(level.dirtcolor - 121, level.dirtcolor - 11, level.dirtcolor,
    level.dirtcolor + 111);
  screen.render(x * 16 + 0, y * 16 + 0, 2 + 32, col, 1);
  screen.render(x * 16 + 8, y * 16 + 0, 2 + 32, col, 0);
  screen.render(x * 16 + 0, y * 16 + 8, 2 + 32, col, 0);
  screen.render(x * 16 + 8, y * 16 + 8, 2 + 32, col, 1);
end;

function TFarmTile.interact(level: TLevel; xt, yt: integer; player: TPlayer;
item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  Result := false;
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.shovel) then
    begin
      if (player.payStamina(4 - Tool.level)) then
      begin
        level.setTile(xt, yt, Resources.dirt, 0);
        Result := true;
      end;
    end
  end;
end;

procedure TFarmTile.Tick(level: TLevel; xt, yt: integer);
var
  age: integer;
begin
  age := level.getData(xt, yt);
  if (age < 5) then
    level.setData(xt, yt, age + 1);
end;

procedure TFarmTile.steppedOn(level: TLevel; xt, yt: integer; entity: TEntity);
begin
  if (random(60) <> 0) then
    exit;
  if (level.getData(xt, yt) < 5) then
    exit;
  level.setTile(xt, yt, Resources.dirt, 0);
end;

{ TDirtTile }

procedure TDirtTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  col: Cardinal;
begin
  col := CalcColor(level.dirtcolor, level.dirtcolor, level.dirtcolor - 111,
    level.dirtcolor - 111);
  screen.render(x * 16 + 0, y * 16 + 0, 0, col, 0);
  screen.render(x * 16 + 8, y * 16 + 0, 1, col, 0);
  screen.render(x * 16 + 0, y * 16 + 8, 2, col, 0);
  screen.render(x * 16 + 8, y * 16 + 8, 3, col, 0);
end;

function TDirtTile.interact(level: TLevel; xt, yt: integer; player: TPlayer;
item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.shovel) then
    begin
      if (player.payStamina(4 - Tool.level)) then
      begin
        level.setTile(xt, yt, Resources.hole, 0);
        level.add(TItemEntity.create(TResourceItem.create(Resources.res_dirt),
          xt * 16 + random(10) + 3, yt * 16 + random(10) + 3));
        Sound.Play(seMonsterHurt);
        Result := true;
        exit;
      end;
    end;
    if (Tool.typ = Tooltypes.hoe) then
    begin
      if (player.payStamina(4 - Tool.level)) then
      begin
        level.setTile(xt, yt, Resources.farmland, 0);
        Sound.Play(seMonsterHurt);
        Result := true;
        exit;
      end;
    end;
  end;
  Result := false;
end;

{ TCactusTile }

constructor TCactusTile.create(id: integer);
begin
  inherited create(id);
  connectsToSand := true;
end;

procedure TCactusTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  col: Cardinal;
begin
  col := CalcColor(20, 40, 50, level.sandcolor);
  screen.render(x * 16 + 0, y * 16 + 0, 8 + 2 * 32, col, 0);
  screen.render(x * 16 + 8, y * 16 + 0, 9 + 2 * 32, col, 0);
  screen.render(x * 16 + 0, y * 16 + 8, 8 + 3 * 32, col, 0);
  screen.render(x * 16 + 8, y * 16 + 8, 9 + 3 * 32, col, 0);
end;

function TCactusTile.mayPass(level: TLevel; x, y: integer; e: TEntity): Boolean;
begin
  Result := false;
end;

procedure TCactusTile.hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
dmg, attackDir: integer);
var
  count, i, damage: integer;
begin
  damage := level.getData(x, y) + dmg;
  level.add(TSmashParticle.create(x * 16 + 8, y * 16 + 8));
  level.add(TTextParticle.create(inttostr(dmg), x * 16 + 8, y * 16 + 8,
    CalcColor(-1, 500, 500, 500)));
  if (damage >= 10) then
  begin
    count := random(2) + 1;
    for i := 0 to count - 1 do
      level.add(TItemEntity.create(TResourceItem.create
        (Resources.res_cactusFlower), x * 16 + random(10) + 3,
        y * 16 + random(10) + 3));
    level.setTile(x, y, Resources.sand, 0);
  end
  else
    level.setData(x, y, damage);
end;

procedure TCactusTile.Tick(level: TLevel; xt, yt: integer);
var
  damage: integer;
begin
  damage := level.getData(xt, yt);
  if (damage > 0) then
    level.setData(xt, yt, damage - 1);
end;

procedure TCactusTile.bumpedInto(level: TLevel; xt, yt: integer;
entity: TEntity);
begin
  entity.hurt(self, xt, yt, 1);
end;

function TCactusTile.getVisibilityBlocking(level: TLevel; x, y: integer;
e: TEntity): integer;
begin
  Result := 20;
end;

{ THoleTime }

constructor THoleTile.create(id: integer);
begin
  inherited create(id);
  connectsToSand := true;
  connectsToWater := true;
  connectsToLava := true;
end;

function THoleTile.mayPass(level: TLevel; x, y: integer; e: TEntity): Boolean;
begin
  Result := e.canSwim();
end;

procedure THoleTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  c, col: Cardinal;
  transitionColor1, transitionColor2: Cardinal;
  u, d, l, r: Boolean;
  su, sd, sl, sr: Boolean;
  i, j: integer;
begin
  col := CalcColor(111, 111, 110, 110);
  transitionColor1 := CalcColor(3, 111, level.dirtcolor - 111, level.dirtcolor);
  transitionColor2 := CalcColor(3, 111, level.sandcolor - 110, level.sandcolor);

  u := not level.getTile(x, y - 1).connectsToLiquid();
  d := not level.getTile(x, y + 1).connectsToLiquid();
  l := not level.getTile(x - 1, y).connectsToLiquid();
  r := not level.getTile(x + 1, y).connectsToLiquid();

  su := u and level.getTile(x, y - 1).connectsToSand;
  sd := d and level.getTile(x, y + 1).connectsToSand;
  sl := l and level.getTile(x - 1, y).connectsToSand;
  sr := r and level.getTile(x + 1, y).connectsToSand;

  if (not u) and (not l) then
  begin
    screen.render(x * 16 + 0, y * 16 + 0, 0, col, 0);
  end
  else
  begin
    if l then
      i := 14
    else
      i := 15;
    if u then
      j := 0
    else
      j := 1;
    if (su or sl) then
      c := transitionColor2
    else
      c := transitionColor1;
    screen.render(x * 16 + 0, y * 16 + 0, i + j * 32, c, 0);
  end;

  if (not u) and (not r) then
  begin
    screen.render(x * 16 + 8, y * 16 + 0, 1, col, 0);
  end
  else
  begin
    if r then
      i := 16
    else
      i := 15;
    if u then
      j := 0
    else
      j := 1;
    if (su or sr) then
      c := transitionColor2
    else
      c := transitionColor1;
    screen.render(x * 16 + 8, y * 16 + 0, i + j * 32, c, 0);
  end;

  if (not d) and (not l) then
  begin
    screen.render(x * 16 + 0, y * 16 + 8, 2, col, 0);
  end
  else
  begin
    if l then
      i := 14
    else
      i := 15;
    if d then
      j := 2
    else
      j := 1;
    if (sd or sl) then
      c := transitionColor2
    else
      c := transitionColor1;
    screen.render(x * 16 + 0, y * 16 + 8, i + j * 32, c, 0);
  end;

  if (not d and not r) then
  begin
    screen.render(x * 16 + 8, y * 16 + 8, 3, col, 0);
  end
  else
  begin
    if r then
      i := 16
    else
      i := 15;
    if d then
      j := 2
    else
      j := 1;
    if (sd or sr) then
      c := transitionColor2
    else
      c := transitionColor1;
    screen.render(x * 16 + 8, y * 16 + 8, i + j * 32, c, 0);
  end;
end;

{ TRockTile }

procedure TRockTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  col, transitionColor: Cardinal;
  u, d, l, r: Boolean;
  ul, dl, ur, dr: Boolean;
  i, j: integer;
begin
  col := CalcColor(444, 444, 333, 333);
  transitionColor := CalcColor(111, 444, 555, level.dirtcolor);

  u := level.getTile(x, y - 1) <> self;
  d := level.getTile(x, y + 1) <> self;
  l := level.getTile(x - 1, y) <> self;
  r := level.getTile(x + 1, y) <> self;

  ul := level.getTile(x - 1, y - 1) <> self;
  dl := level.getTile(x - 1, y + 1) <> self;
  ur := level.getTile(x + 1, y - 1) <> self;
  dr := level.getTile(x + 1, y + 1) <> self;

  if (not u) and (not l) then
  begin
    if (not ul) then
      screen.render(x * 16 + 0, y * 16 + 0, 0, col, 0)
    else
      screen.render(x * 16 + 0, y * 16 + 0, 7 + 0 * 32, transitionColor, 3);
  end
  else
  begin
    if l then
      i := 6
    else
      i := 5;
    if u then
      j := 2
    else
      j := 1;
    screen.render(x * 16 + 0, y * 16 + 0, i + j * 32, transitionColor, 3);
  end;

  if (not u) and (not r) then
  begin
    if (not ur) then
      screen.render(x * 16 + 8, y * 16 + 0, 1, col, 0)
    else
      screen.render(x * 16 + 8, y * 16 + 0, 8 + 0 * 32, transitionColor, 3);
  end
  else
  begin
    if r then
      i := 4
    else
      i := 5;
    if u then
      j := 2
    else
      j := 1;

    screen.render(x * 16 + 8, y * 16 + 0, i + j * 32, transitionColor, 3);
  end;

  if (not d) and (not l) then
  begin
    if (not dl) then
      screen.render(x * 16 + 0, y * 16 + 8, 2, col, 0)
    else
      screen.render(x * 16 + 0, y * 16 + 8, 7 + 1 * 32, transitionColor, 3);
  end
  else
  begin
    if l then
      i := 6
    else
      i := 5;
    if d then
      j := 0
    else
      j := 1;
    screen.render(x * 16 + 0, y * 16 + 8, i + j * 32, transitionColor, 3);
  end;
  if (not d) and (not r) then
  begin
    if (not dr) then
      screen.render(x * 16 + 8, y * 16 + 8, 3, col, 0)
    else
      screen.render(x * 16 + 8, y * 16 + 8, 8 + 1 * 32, transitionColor, 3);
  end
  else
  begin
    if r then
      i := 4
    else
      i := 5;
    if d then
      j := 0
    else
      j := 1;
    screen.render(x * 16 + 8, y * 16 + 8, i + j * 32, transitionColor, 3);
  end;
end;

function TRockTile.mayPass(level: TLevel; x, y: integer; e: TEntity): Boolean;
begin
  Result := false;
end;

procedure TRockTile.hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
dmg, attackDir: integer);
begin
  hurt(level, x, y, dmg);
end;

procedure TRockTile.hurt(level: TLevel; x, y, dmg: integer);
var
  count, i, damage: integer;
begin
  damage := level.getData(x, y) + dmg;
  level.add(TSmashParticle.create(x * 16 + 8, y * 16 + 8));
  level.add(TTextParticle.create(inttostr(dmg), x * 16 + 8, y * 16 + 8,
    CalcColor(-1, 500, 500, 500)));
  if (damage >= 50) then
  begin
    count := random(4) + 1;
    for i := 0 to count - 1 do
      level.add(TItemEntity.create(TResourceItem.create(Resources.res_stone),
        x * 16 + random(10) + 3, y * 16 + random(10) + 3));
    count := random(2);
    for i := 0 to count - 1 do
    begin
      level.add(TItemEntity.create(TResourceItem.create(Resources.res_coal),
        x * 16 + random(10) + 3, y * 16 + random(10) + 3));
    end;
    level.setTile(x, y, Resources.dirt, 0);
  end
  else
    level.setData(x, y, damage);
end;

function TRockTile.interact(level: TLevel; xt, yt: integer; player: TPlayer;
item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  Result := false;
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.pickaxe) then
    begin
      if (player.payStamina(4 - Tool.level)) then
      begin
        hurt(level, xt, yt, random(10) + (Tool.level) * 5 + 10);
        Result := true;
      end;
    end;
  end;
end;

procedure TRockTile.Tick(level: TLevel; xt, yt: integer);
var
  damage: integer;
begin
  damage := level.getData(xt, yt);
  if (damage > 0) then
    level.setData(xt, yt, damage - 1);
end;

{ TTreeTile }

constructor TTreeTile.create(id: integer);
begin
  inherited create(id);
  connectsToGrass := true;
end;

procedure TTreeTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  col, barkCol1, barkCol2: Cardinal;
  u, l, d, r: Boolean;
  ul, ur, dl, dr: Boolean;
begin
  col := CalcColor(10, 30, 151, level.grasscolor);
  barkCol1 := CalcColor(10, 30, 430, level.grasscolor);
  barkCol2 := CalcColor(10, 30, 320, level.grasscolor);

  u := level.getTile(x, y - 1) = self;
  l := level.getTile(x - 1, y) = self;
  r := level.getTile(x + 1, y) = self;
  d := level.getTile(x, y + 1) = self;
  ul := level.getTile(x - 1, y - 1) = self;
  ur := level.getTile(x + 1, y - 1) = self;
  dl := level.getTile(x - 1, y + 1) = self;
  dr := level.getTile(x + 1, y + 1) = self;

  if (u) and (ul) and (l) then
    screen.render(x * 16 + 0, y * 16 + 0, 10 + 1 * 32, col, 0)
  else
    screen.render(x * 16 + 0, y * 16 + 0, 9 + 0 * 32, col, 0);

  if (u) and (ur) and (r) then
    screen.render(x * 16 + 8, y * 16 + 0, 10 + 2 * 32, barkCol2, 0)
  else
    screen.render(x * 16 + 8, y * 16 + 0, 10 + 0 * 32, col, 0);

  if (d) and (dl) and (l) then
    screen.render(x * 16 + 0, y * 16 + 8, 10 + 2 * 32, barkCol2, 0)
  else
    screen.render(x * 16 + 0, y * 16 + 8, 9 + 1 * 32, barkCol1, 0);

  if (d) and (dr) and (r) then
    screen.render(x * 16 + 8, y * 16 + 8, 10 + 1 * 32, col, 0)
  else
    screen.render(x * 16 + 8, y * 16 + 8, 10 + 3 * 32, barkCol2, 0)
end;

procedure TTreeTile.Tick(level: TLevel; xt, yt: integer);
var
  xa, ya, damage: integer;
begin
  damage := level.getData(xt, yt);
  if (damage > 0) then
    level.setData(xt, yt, damage - 1);

  // grow
  if (random(1000) = 0) then
  begin
    xa := xt + random(2) * 2 - 1;
    ya := yt + random(2) * 2 - 1;
    if (level.getTile(xa, ya) = Resources.grass) then
    begin
      level.setTile(xa, ya, Resources.treeSapling, 0);
    end;
  end;
  // die
  if (random(2000) = 0) then
  begin
    level.setTile(xt, yt, Resources.grass, 0);
  end;
end;

function TTreeTile.mayPass(level: TLevel; x, y: integer; e: TEntity): Boolean;
begin
  Result := false;
end;

procedure TTreeTile.hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
dmg, attackDir: integer);
begin
  hurt(level, x, y, dmg);
end;

function TTreeTile.interact(level: TLevel; xt, yt: integer; player: TPlayer;
item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  Result := false;
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.axe) then
    begin
      if (player.payStamina(4 - Tool.level)) then
      begin
        hurt(level, xt, yt, random(10) + (Tool.level) * 5 + 10);
        Result := true;
      end;
    end;
  end;
end;

procedure TTreeTile.hurt(level: TLevel; x, y, dmg: integer);
var
  i, count: integer;
  damage: integer;
begin
  if random(10) = 0 then
    count := 1
  else
    count := 0;
  for i := 0 to count - 1 do
    level.add(TItemEntity.create(TResourceItem.create(Resources.res_apple),
      x * 16 + random(10) + 3, y * 16 + random(10) + 3));

  damage := level.getData(x, y) + dmg;
  level.add(TSmashParticle.create(x * 16 + 8, y * 16 + 8));
  level.add(TTextParticle.create(inttostr(dmg), x * 16 + 8, y * 16 + 8,
    CalcColor(-1, 500, 500, 500)));
  if (damage >= 20) then
  begin
    count := random(2) + 1;
    for i := 0 to count - 1 do
    begin
      level.add(TItemEntity.create(TResourceItem.create(Resources.res_wood),
        x * 16 + random(10) + 3, y * 16 + random(10) + 3));
    end;
    count := random(random(4) + 1);
    for i := 0 to count - 1 do
    begin
      level.add(TItemEntity.create(TResourceItem.create(Resources.res_acorn),
        x * 16 + random(10) + 3, y * 16 + random(10) + 3));
    end;
    level.setTile(x, y, Resources.grass, 0);
  end
  else
    level.setData(x, y, damage);
end;

function TTreeTile.getVisibilityBlocking(level: TLevel; x: integer; y: integer;
e: TEntity): integer;
begin
  Result := 50;
end;

function TTreeTile.getFireFuelAmount(level: TLevel; xt: integer;
yt: integer): integer;
begin
  Result := 20 - level.getData(xt, yt);
end;

procedure TTreeTile.burnFireFuel(level: TLevel; xt: integer; yt: integer;
burnPower: integer; ent: TEntity);
var
  damage: integer;
begin
  damage := level.getData(xt, yt) + burnPower;
  if (damage >= 20) then
    level.setTile(xt, yt, Resources.dirt, 0)
  else
    level.setData(xt, yt, damage);
end;

{ TCloudTile }

procedure TCloudTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  col, transitionColor: Cardinal;
  u, d, l, r: Boolean;
  ul, dl, ur, dr: Boolean;
  i, j: integer;
begin
  col := CalcColor(444, 444, 555, 555);
  transitionColor := CalcColor(333, 444, 555, -1);

  u := level.getTile(x, y - 1) = Resources.infiniteFall;
  d := level.getTile(x, y + 1) = Resources.infiniteFall;
  l := level.getTile(x - 1, y) = Resources.infiniteFall;
  r := level.getTile(x + 1, y) = Resources.infiniteFall;

  ul := level.getTile(x - 1, y - 1) = Resources.infiniteFall;
  dl := level.getTile(x - 1, y + 1) = Resources.infiniteFall;
  ur := level.getTile(x + 1, y - 1) = Resources.infiniteFall;
  dr := level.getTile(x + 1, y + 1) = Resources.infiniteFall;

  if (not u) and (not l) then
  begin
    if (not ul) then
      screen.render(x * 16 + 0, y * 16 + 0, 17, col, 0)
    else
      screen.render(x * 16 + 0, y * 16 + 0, 7 + 0 * 32, transitionColor, 3);
  end
  else
  begin
    if l then
      i := 6
    else
      i := 5;
    if u then
      j := 2
    else
      j := 1;
    screen.render(x * 16 + 0, y * 16 + 0, i + j * 32, transitionColor, 3);
  end;

  if (not u) and (not r) then
  begin
    if (not ur) then
      screen.render(x * 16 + 8, y * 16 + 0, 18, col, 0)
    else
      screen.render(x * 16 + 8, y * 16 + 0, 8 + 0 * 32, transitionColor, 3);
  end
  else
  begin
    if r then
      i := 4
    else
      i := 5;
    if u then
      j := 2
    else
      j := 1;
    screen.render(x * 16 + 8, y * 16 + 0, i + j * 32, transitionColor, 3);
  end;

  if (not d) and (not l) then
  begin
    if (not dl) then
      screen.render(x * 16 + 0, y * 16 + 8, 20, col, 0)
    else
      screen.render(x * 16 + 0, y * 16 + 8, 7 + 1 * 32, transitionColor, 3);
  end
  else
  begin
    if l then
      i := 6
    else
      i := 5;
    if d then
      j := 0
    else
      j := 1;
    screen.render(x * 16 + 0, y * 16 + 8, i + j * 32, transitionColor, 3);
  end;

  if (not d) and (not r) then
  begin
    if (not dr) then
      screen.render(x * 16 + 8, y * 16 + 8, 19, col, 0)
    else
      screen.render(x * 16 + 8, y * 16 + 8, 8 + 1 * 32, transitionColor, 3);
  end
  else
  begin
    if r then
      i := 4
    else
      i := 5;
    if d then
      j := 0
    else
      j := 1;
    screen.render(x * 16 + 8, y * 16 + 8, i + j * 32, transitionColor, 3);
  end;
end;

function TCloudTile.mayPass(level: TLevel; x, y: integer; e: TEntity): Boolean;
begin
  Result := true;
end;

function TCloudTile.interact(level: TLevel; xt, yt: integer; player: TPlayer;
item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
  i, count: integer;
begin
  Result := false;
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.shovel) then
    begin
      if (player.payStamina(5)) then
      begin
        count := random(2) + 1;
        for i := 0 to count - 1 do
          level.add(TItemEntity.create(TResourceItem.create
            (Resources.res_cloud), xt * 16 + random(10) + 3,
            yt * 16 + random(10) + 3));
        Result := true;
      end;
    end;
  end;
end;

{ TGrassTile }

constructor TGrassTile.create(id: integer);
begin
  inherited create(id);
  connectsToGrass := true;
end;

procedure TGrassTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  col, transitionColor: Cardinal;
  u, d, l, r: Boolean;
  i, j: integer;
begin
  col := CalcColor(level.grasscolor, level.grasscolor, level.grasscolor + 111,
    level.grasscolor + 111);
  transitionColor := CalcColor(level.grasscolor - 111, level.grasscolor,
    level.grasscolor + 111, level.dirtcolor);

  u := not level.getTile(x, y - 1).connectsToGrass;
  d := not level.getTile(x, y + 1).connectsToGrass;
  l := not level.getTile(x - 1, y).connectsToGrass;
  r := not level.getTile(x + 1, y).connectsToGrass;

  if (not u) and (not l) then
    screen.render(x * 16 + 0, y * 16 + 0, 0, col, 0)
  else
  begin
    if l then
      i := 11
    else
      i := 12;
    if u then
      j := 0
    else
      j := 1;
    screen.render(x * 16 + 0, y * 16 + 0, i + j * 32, transitionColor, 0);
  end;

  if (not u) and (not r) then
    screen.render(x * 16 + 8, y * 16 + 0, 1, col, 0)
  else
  begin
    if r then
      i := 13
    else
      i := 12;
    if u then
      j := 0
    else
      j := 1;
    screen.render(x * 16 + 8, y * 16 + 0, i + j * 32, transitionColor, 0);
  end;

  if (not d) and (not l) then
    screen.render(x * 16 + 0, y * 16 + 8, 2, col, 0)
  else
  begin
    if l then
      i := 11
    else
      i := 12;
    if d then
      j := 2
    else
      j := 1;
    screen.render(x * 16 + 0, y * 16 + 8, i + j * 32, transitionColor, 0);
  end;

  if (not d) and (not r) then
    screen.render(x * 16 + 8, y * 16 + 8, 3, col, 0)
  else
  begin
    if r then
      i := 13
    else
      i := 12;
    if d then
      j := 2
    else
      j := 1;
    screen.render(x * 16 + 8, y * 16 + 8, i + j * 32, transitionColor, 0);
  end;
end;

procedure TGrassTile.Tick(level: TLevel; xt, yt: integer);
var
  xn, yn: integer;
begin
  if (random(40) <> 0) then
    exit;

  xn := xt;
  yn := yt;

  if random(1) = 1 then
    xn := xn + random(2) * 2 - 1
  else
    yn := yn + random(2) * 2 - 1;

  if (level.getTile(xn, yn) = Resources.dirt) then
  begin
    level.setTile(xn, yn, self, 0);
  end;
end;

function TGrassTile.interact(level: TLevel; xt, yt: integer; player: TPlayer;
item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  Result := false;
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.shovel) then
    begin
      if (player.payStamina(4 - Tool.level)) then
      begin
        level.setTile(xt, yt, Resources.dirt, 0);
        Sound.Play(seMonsterHurt);
        if (random(5) = 0) then
        begin
          level.add(TItemEntity.create(TResourceItem.Create(Resources.res_seeds),
            xt * 16 + random(10) + 3, yt * 16 + random(10) + 3));
          Result := true;
          exit;
        end;
      end;
    end;
    if (Tool.typ = Tooltypes.hoe) then
    begin
      if (player.payStamina(4 - Tool.level)) then
      begin
        Sound.Play(seMonsterHurt);
        if (random(5) = 0) then
        begin
          level.add(TItemEntity.create(TResourceItem.create
            (Resources.res_seeds), xt * 16 + random(10) + 3,
            yt * 16 + random(10) + 3));
          Result := true;
          exit;
        end;
        level.setTile(xt, yt, Resources.farmland, 0);
        Result := true;
      end;
    end;
  end;
end;

function TGrassTile.getVisibilityBlocking(level: TLevel; x, y: integer;
e: TEntity): integer;
begin
  Result := 5;
end;

function TGrassTile.getFireFuelAmount(level: TLevel; xt, yt: integer): integer;
begin
  Result := 1;
end;

procedure TGrassTile.burnFireFuel(level: TLevel; xt, yt, burnPower: integer;
ent: TEntity);
begin
  level.setTile(xt, yt, Resources.dirt, 0);
end;

{ TSandTile }

constructor TSandTile.create(id: integer);
begin
  inherited create(id);
  connectsToSand := true;
end;

procedure TSandTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  col, transitionColor: Cardinal;
  u, d, l, r: Boolean;
  steppedOn: Boolean;
  i, j: integer;
begin
  col := CalcColor(level.sandcolor + 2, level.sandcolor, level.sandcolor - 110,
    level.sandcolor - 110);
  transitionColor := CalcColor(level.sandcolor - 110, level.sandcolor,
    level.sandcolor - 110, level.dirtcolor);

  u := not level.getTile(x, y - 1).connectsToSand;
  d := not level.getTile(x, y + 1).connectsToSand;
  l := not level.getTile(x - 1, y).connectsToSand;
  r := not level.getTile(x + 1, y).connectsToSand;

  steppedOn := level.getData(x, y) > 0;

  if (not u) and (not l) then
  begin
    if (not steppedOn) then
      screen.render(x * 16 + 0, y * 16 + 0, 0, col, 0)
    else
      screen.render(x * 16 + 0, y * 16 + 0, 3 + 1 * 32, col, 0);
  end
  else
  begin
    if l then
      i := 11
    else
      i := 12;
    if u then
      j := 0
    else
      j := 1;
    screen.render(x * 16 + 0, y * 16 + 0, i + j * 32, transitionColor, 0);
  end;

  if (not u) and (not r) then
    screen.render(x * 16 + 8, y * 16 + 0, 1, col, 0)
  else
  begin
    if r then
      i := 13
    else
      i := 12;
    if u then
      j := 0
    else
      j := 1;
    screen.render(x * 16 + 8, y * 16 + 0, i + j * 32, transitionColor, 0);
  end;

  if (not d) and (not l) then
    screen.render(x * 16 + 0, y * 16 + 8, 2, col, 0)
  else
  begin
    if l then
      i := 11
    else
      i := 12;
    if d then
      j := 2
    else
      j := 1;
    screen.render(x * 16 + 0, y * 16 + 8, i + j * 32, transitionColor, 0);
  end;

  if (not d) and (not r) then
  begin
    if (not steppedOn) then
      screen.render(x * 16 + 8, y * 16 + 8, 3, col, 0)
    else
      screen.render(x * 16 + 8, y * 16 + 8, 3 + 1 * 32, col, 0);
  end
  else
  begin
    if r then
      i := 13
    else
      i := 12;
    if d then
      j := 2
    else
      j := 1;
    screen.render(x * 16 + 8, y * 16 + 8, i + j * 32, transitionColor, 0);
  end;
end;

procedure TSandTile.Tick(level: TLevel; xt, yt: integer);
var
  d: integer;
begin
  d := level.getData(xt, yt);
  if (d > 0) then
    level.setData(xt, yt, d - 1);
end;

procedure TSandTile.steppedOn(level: TLevel; xt, yt: integer; entity: TEntity);
begin
  if entity is TMob then
    level.setData(xt, yt, 10);
end;

function TSandTile.interact(level: TLevel; xt, yt: integer; player: TPlayer;
item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  Result := false;
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.shovel) then
    begin
      if (player.payStamina(4 - Tool.level)) then
      begin
        level.setTile(xt, yt, Resources.dirt, 0);
        level.add(TItemEntity.create(TResourceItem.create(Resources.res_sand),
          xt * 16 + random(10) + 3, yt * 16 + random(10) + 3));
        Result := true;
      end;
    end;
  end;
end;

{ TWheatTile }

procedure TWheatTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  age: integer;
  col: Cardinal;
  icon: integer;
begin
  age := level.getData(x, y);
  col := CalcColor(level.dirtcolor - 121, level.dirtcolor - 11,
    level.dirtcolor, 50);
  icon := age div 10;
  if (icon >= 3) then
  begin
    col := CalcColor(level.dirtcolor - 121, level.dirtcolor - 11,
      50 + (icon) * 100, 40 + (icon - 3) * 2 * 100);
    if (age = 50) then
      col := CalcColor(0, 0, 50 + (icon) * 100, 40 + (icon - 3) * 2 * 100);
    icon := 3;
  end;

  screen.render(x * 16 + 0, y * 16 + 0, 4 + 3 * 32 + icon, col, 0);
  screen.render(x * 16 + 8, y * 16 + 0, 4 + 3 * 32 + icon, col, 0);
  screen.render(x * 16 + 0, y * 16 + 8, 4 + 3 * 32 + icon, col, 1);
  screen.render(x * 16 + 8, y * 16 + 8, 4 + 3 * 32 + icon, col, 1);
end;

procedure TWheatTile.Tick(level: TLevel; xt, yt: integer);
var
  age: integer;
begin
  if (random(2) = 0) then
    exit;

  age := level.getData(xt, yt);
  if (age < 50) then
    level.setData(xt, yt, age + 1);
end;

procedure TWheatTile.steppedOn(level: TLevel; xt, yt: integer; entity: TEntity);
begin
  if (random(60) <> 0) then
    exit;
  if (level.getData(xt, yt) < 2) then
    exit;
  harvest(level, xt, yt);
end;

function TWheatTile.interact(level: TLevel; xt, yt: integer; player: TPlayer;
item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  Result := false;
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.shovel) then
    begin
      if (player.payStamina(4 - Tool.level)) then
      begin
        level.setTile(xt, yt, Resources.dirt, 0);
        Result := true;
      end;
    end;
  end;
end;

procedure TWheatTile.hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
dmg, attackDir: integer);
begin
  harvest(level, x, y);
end;

procedure TWheatTile.harvest(level: TLevel; x, y: integer);
var
  i, count, age: integer;
begin
  age := level.getData(x, y);

  count := random(2);
  for i := 0 to count - 1 do
    level.add(TItemEntity.create(TResourceItem.create(Resources.res_seeds),
      x * 16 + random(10) + 3, y * 16 + random(10) + 3));

  count := 0;
  if (age = 50) then
    count := random(3) + 2
  else if (age >= 40) then
    count := random(2) + 1;

  for i := 0 to count - 1 do
    level.add(TItemEntity.create(TResourceItem.create(Resources.res_wheat),
      x * 16 + random(10) + 3, y * 16 + random(10) + 3));

  level.setTile(x, y, Resources.dirt, 0);
end;

function TWheatTile.getFireFuelAmount(level: TLevel; xt, yt: integer): integer;
begin
  Result := level.getData(xt, yt);
end;

procedure TWheatTile.burnFireFuel(level: TLevel; xt, yt, burnPower: integer;
ent: TEntity);
var
  hp: integer;
begin
  hp := level.getData(xt, yt) - burnPower;
  if (hp <= 0) then
    level.setTile(xt, yt, Resources.farmland, 0)
  else
    level.setData(xt, yt, hp);
end;

{ TCloudCactusTile }

procedure TCloudCactusTile.render(screen: TScreen; level: TLevel;
x, y: integer);
var
  color: Cardinal;
begin
  color := CalcColor(444, 111, 333, 555);
  screen.render(x * 16 + 0, y * 16 + 0, 17 + 1 * 32, color, 0);
  screen.render(x * 16 + 8, y * 16 + 0, 18 + 1 * 32, color, 0);
  screen.render(x * 16 + 0, y * 16 + 8, 17 + 2 * 32, color, 0);
  screen.render(x * 16 + 8, y * 16 + 8, 18 + 2 * 32, color, 0);
end;

function TCloudCactusTile.mayPass(level: TLevel; x, y: integer;
e: TEntity): Boolean;
begin
  Result := e is TAirwizard;
end;

procedure TCloudCactusTile.hurt(level: TLevel; x, y: integer;
Source: TLivingEntity; dmg, attackDir: integer);
begin
  hurt(level, x, y, 0);
end;

function TCloudCactusTile.interact(level: TLevel; xt, yt: integer;
player: TPlayer; item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  Result := false;
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.pickaxe) then
    begin
      if (player.payStamina(6 - Tool.level)) then
      begin
        hurt(level, xt, yt, 1);
        Result := true;
      end;
    end;
  end;
end;

procedure TCloudCactusTile.hurt(level: TLevel; x, y, dmg: integer);
var
  damage: integer;
begin
  damage := level.getData(x, y) + 1;
  level.add(TSmashParticle.create(x * 16 + 8, y * 16 + 8));
  level.add(TTextParticle.create(inttostr(dmg), x * 16 + 8, y * 16 + 8,
    CalcColor(-1, 500, 500, 500)));
  if (dmg > 0) then
    if (damage >= 10) then
      level.setTile(x, y, Resources.cloud, 0)
    else
      level.setData(x, y, damage);
end;

procedure TCloudCactusTile.bumpedInto(level: TLevel; xt, yt: integer;
entity: TEntity);
begin
  if (entity is TAirwizard) then
    exit;
  entity.hurt(self, xt, yt, 3);
end;

{ TFlowerTile }

constructor TFlowerTile.create(id: integer);
begin
  inherited create(id);
  connectsToGrass := true;
end;

procedure TFlowerTile.render(screen: TScreen; level: TLevel; x, y: integer);
const
  flowerColors: array [0 .. 3] of integer = (555, 455, 545, 554);

var
  data, shape: integer;
  headcolor, flowercol: Cardinal;
begin
  inherited render(screen, level, x, y);

  data := level.getData(x, y);
  shape := (data div 16) mod 2;
  headcolor := flowerColors[(data * 7 + x * 13 + y * level.w * 3)
    mod high(flowerColors)];
  flowercol := CalcColor(10, level.grasscolor, headcolor, 440);

  // flowercol := CalcColor(10, level.grasscolor, 555, 440);

  if (shape = 0) then
    screen.render(x * 16 + 0, y * 16 + 0, 1 + 1 * 32, flowercol, 0);
  if (shape = 1) then
    screen.render(x * 16 + 8, y * 16 + 0, 1 + 1 * 32, flowercol, 0);
  if (shape = 1) then
    screen.render(x * 16 + 0, y * 16 + 8, 1 + 1 * 32, flowercol, 0);
  if (shape = 0) then
    screen.render(x * 16 + 8, y * 16 + 8, 1 + 1 * 32, flowercol, 0);
end;

function TFlowerTile.interact(level: TLevel; xt, yt: integer; player: TPlayer;
item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  Result := false;
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.shovel) then
    begin
      if (player.payStamina(4 - Tool.level)) then
      begin
        level.add(TItemEntity.create(TResourceItem(Resources.flower).create,
          xt * 16 + random(10) + 3, yt * 16 + random(10) + 3));
        level.add(TItemEntity.create(TResourceItem(Resources.flower).create,
          xt * 16 + random(10) + 3, yt * 16 + random(10) + 3));
        level.setTile(xt, yt, Resources.grass, 0);
        Result := true;
      end;
    end;
  end;
end;

procedure TFlowerTile.hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
dmg, attackDir: integer);
var
  count, i: integer;
begin
  count := random(2) + 1;
  for i := 0 to count - 1 do
    level.add(TItemEntity.create(TResourceItem.create(Resources.res_flower),
      x * 16 + random(10) + 3, y * 16 + random(10) + 3));
  level.setTile(x, y, Resources.grass, 0);
end;

function TFlowerTile.getFireFuelAmount(level: TLevel; xt, yt: integer): integer;
begin
  Result := 1;
end;

procedure TFlowerTile.burnFireFuel(level: TLevel; xt, yt, burnPower: integer;
ent: TEntity);
begin
  level.setTile(xt, yt, Resources.dirt, 0);
end;

{ TOreTile }

constructor TOreTile.create(id: integer; toDrop: TResource);
begin
  inherited create(id);
  self.toDrop := toDrop;
  self.color := toDrop.color and $FFFF00;
end;

procedure TOreTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  color: Cardinal;
begin
  color := (toDrop.color and $FFFFFF00) + CalcColor(level.dirtcolor);
  screen.render(x * 16 + 0, y * 16 + 0, 17 + 1 * 32, color, 0);
  screen.render(x * 16 + 8, y * 16 + 0, 18 + 1 * 32, color, 0);
  screen.render(x * 16 + 0, y * 16 + 8, 17 + 2 * 32, color, 0);
  screen.render(x * 16 + 8, y * 16 + 8, 18 + 2 * 32, color, 0);
end;

function TOreTile.mayPass(level: TLevel; x, y: integer; e: TEntity): Boolean;
begin
  Result := false;
end;

procedure TOreTile.hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
dmg, attackDir: integer);
begin
  hurt(level, x, y, 0);
end;

function TOreTile.interact(level: TLevel; xt, yt: integer; player: TPlayer;
item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  Result := false;
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.pickaxe) then
    begin
      if (player.payStamina(6 - Tool.level)) then
      begin
        hurt(level, xt, yt, 1);
        Result := true;
      end;
    end;
  end;
end;

procedure TOreTile.hurt(level: TLevel; x, y, dmg: integer);
var
  i, count, damage: integer;
begin
  damage := level.getData(x, y) + 1;
  level.add(TSmashParticle.create(x * 16 + 8, y * 16 + 8));
  level.add(TTextParticle.create(inttostr(dmg), x * 16 + 8, y * 16 + 8,
    CalcColor(-1, 500, 500, 500)));
  if (dmg > 0) then
  begin
    count := random(2);
    if (damage >= random(10) + 3) then
    begin
      level.setTile(x, y, Resources.dirt, 0);
      inc(count, 2);
    end
    else
      level.setData(x, y, damage);

    for i := 0 to count - 1 do
      level.add(TItemEntity.create(TResourceItem.create(toDrop),
        x * 16 + random(10) + 3, y * 16 + random(10) + 3));
  end;
end;

procedure TOreTile.bumpedInto(level: TLevel; xt, yt: integer; entity: TEntity);
begin
  entity.hurt(self, xt, yt, 3);
end;

{ TWaterTile }

constructor TWaterTile.create(id: integer);
begin
  inherited create(id);
  connectsToSand := true;
  connectsToWater := true;
end;

procedure TWaterTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  c, col, transitionColor1, transitionColor2: Cardinal;
  u, d, l, r: Boolean;
  su, sd, sl, sr: Boolean;
  i, j: integer;
begin
  DoRandSeed(x, y);
  col := CalcColor(005, 005, 115, 115);
  transitionColor1 := CalcColor(3, 005, level.dirtcolor - 111, level.dirtcolor);
  transitionColor2 := CalcColor(3, 005, level.sandcolor - 110, level.sandcolor);

  u := not level.getTile(x, y - 1).connectsToWater;
  d := not level.getTile(x, y + 1).connectsToWater;
  l := not level.getTile(x - 1, y).connectsToWater;
  r := not level.getTile(x + 1, y).connectsToWater;

  su := u and level.getTile(x, y - 1).connectsToSand;
  sd := d and level.getTile(x, y + 1).connectsToSand;
  sl := l and level.getTile(x - 1, y).connectsToSand;
  sr := r and level.getTile(x + 1, y).connectsToSand;

  if (not u) and (not l) then
  begin
    screen.render(x * 16 + 0, y * 16 + 0, random(4), col, random(4));
  end
  else
  begin
    if l then
      i := 14
    else
      i := 15;
    if u then
      j := 0
    else
      j := 1;
    if su or sl then
      c := transitionColor2
    else
      c := transitionColor1;
    screen.render(x * 16 + 0, y * 16 + 0, i + j * 32, c, 0);
  end;

  if (not u) and (not r) then
    screen.render(x * 16 + 8, y * 16 + 0, random(4), col, random(4))
  else
  begin
    if r then
      i := 16
    else
      i := 15;
    if u then
      j := 0
    else
      j := 1;
    if su or sr then
      c := transitionColor2
    else
      c := transitionColor1;

    screen.render(x * 16 + 8, y * 16 + 0, i + j * 32, c, 0);
  end;

  if (not d) and (not l) then
    screen.render(x * 16 + 0, y * 16 + 8, random(4), col, random(4))
  else
  begin
    if l then
      i := 14
    else
      i := 15;
    if d then
      j := 2
    else
      j := 1;
    if sd or sl then
      c := transitionColor2
    else
      c := transitionColor1;
    screen.render(x * 16 + 0, y * 16 + 8, i + j * 32, c, 0);
  end;

  if (not d) and (not r) then
    screen.render(x * 16 + 8, y * 16 + 8, random(4), col, random(4))
  else
  begin
    if r then
      i := 16
    else
      i := 15;
    if d then
      j := 2
    else
      j := 1;
    if sd or sr then
      c := transitionColor2
    else
      c := transitionColor1;
    screen.render(x * 16 + 8, y * 16 + 8, i + j * 32, c, 0);
  end;
end;

function TWaterTile.mayPass(level: TLevel; x, y: integer; e: TEntity): Boolean;
begin
  Result := e.canSwim();
end;

procedure TWaterTile.Tick(level: TLevel; xt, yt: integer);
var
  xn, yn: integer;
begin
  xn := xt;
  yn := yt;

  if random(1) = 1 then
    xn := xn + random(2) * 2 - 1
  else
    yn := yn + random(2) * 2 - 1;

  if (level.getTile(xn, yn) = Resources.hole) then
    level.setTile(xn, yn, self, 0);
end;

function TWaterTile.getVisibilityBlocking(level: TLevel; x: integer; y: integer;
e: TEntity): integer;
begin
  Result := 0;
end;

{ TLavaTile }

constructor TLavaTile.create(id: integer);
begin
  inherited create(id);
  connectsToSand := true;
  connectsToLava := true;
end;

procedure TLavaTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  c, col, transitionColor1, transitionColor2: Cardinal;
  u, d, l, r: Boolean;
  su, sd, sl, sr: Boolean;
  i, j: integer;
begin
  DoRandSeed(x, y);
  col := CalcColor(500, 500, 520, 550);
  transitionColor1 := CalcColor(3, 500, level.dirtcolor - 111, level.dirtcolor);
  transitionColor2 := CalcColor(3, 500, level.sandcolor - 110, level.sandcolor);

  u := not level.getTile(x, y - 1).connectsToLava;
  d := not level.getTile(x, y + 1).connectsToLava;
  l := not level.getTile(x - 1, y).connectsToLava;
  r := not level.getTile(x + 1, y).connectsToLava;

  su := u and level.getTile(x, y - 1).connectsToSand;
  sd := d and level.getTile(x, y + 1).connectsToSand;
  sl := l and level.getTile(x - 1, y).connectsToSand;
  sr := r and level.getTile(x + 1, y).connectsToSand;

  if (not u) and (not l) then
    screen.render(x * 16 + 0, y * 16 + 0, random(4), col, random(4))
  else
  begin
    if l then
      i := 14
    else
      i := 15;
    if u then
      j := 0
    else
      j := 1;
    if su or sl then
      c := transitionColor2
    else
      c := transitionColor1;
    screen.render(x * 16 + 0, y * 16 + 0, i + j * 32, c, 0);
  end;

  if (not u) and (not r) then
    screen.render(x * 16 + 8, y * 16 + 0, random(4), col, random(4))
  else
  begin
    if r then
      i := 16
    else
      i := 15;
    if u then
      j := 0
    else
      j := 1;
    if su or sr then
      c := transitionColor2
    else
      c := transitionColor1;

    screen.render(x * 16 + 8, y * 16 + 0, i + j * 32, c, 0);
  end;

  if (not d) and (not l) then
    screen.render(x * 16 + 0, y * 16 + 8, random(4), col, random(4))
  else
  begin
    if l then
      i := 14
    else
      i := 15;
    if d then
      j := 2
    else
      j := 1;
    if sd or sl then
      c := transitionColor2
    else
      c := transitionColor1;

    screen.render(x * 16 + 0, y * 16 + 8, i + j * 32, c, 0);
  end;

  if (not d) and (not r) then
    screen.render(x * 16 + 8, y * 16 + 8, random(4), col, random(4))
  else
  begin
    if r then
      i := 16
    else
      i := 15;
    if d then
      j := 2
    else
      j := 1;
    if sd or sr then
      c := transitionColor2
    else
      c := transitionColor1;

    screen.render(x * 16 + 8, y * 16 + 8, i + j * 32, c, 0);
  end;
end;

function TLavaTile.mayPass(level: TLevel; x, y: integer; e: TEntity): Boolean;
begin
  Result := e.canSwim();
end;

procedure TLavaTile.Tick(level: TLevel; xt, yt: integer);
var
  xn, yn: integer;
begin
  xn := xt;
  yn := yt;

  if (random(1) = 1) then
    xn := xn + random(2) * 2 - 1
  else
    yn := yn + random(2) * 2 - 1;

  if (level.getTile(xn, yn) = Resources.hole) then
    level.setTile(xn, yn, self, 0);
end;

function TLavaTile.getLightRadius(level: TLevel; x, y: integer): integer;
begin
  Result := 6;
end;

{ TWoodenWallTile }

procedure TWoodenWallTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  col, transitionColor: Cardinal;
  u, d, l, r: Boolean;
  ul, dl, ur, dr: Boolean;

  lt, ut: integer;
begin
  col := CalcColor(310, 420, 530, 333);
  transitionColor := CalcColor(310, 420, 530, level.dirtcolor);

  u := level.getTile(x, y - 1) <> self;
  d := level.getTile(x, y + 1) <> self;
  l := level.getTile(x - 1, y) <> self;
  r := level.getTile(x + 1, y) <> self;

  ul := level.getTile(x - 1, y - 1) <> self;
  dl := level.getTile(x - 1, y + 1) <> self;
  ur := level.getTile(x + 1, y - 1) <> self;
  dr := level.getTile(x + 1, y + 1) <> self;

  // attach to door
  if (level.getTile(x, y - 1) = Resources.door) or
    (level.getTile(x, y - 1) = Resources.window) then
    u := false;

  if (level.getTile(x, y + 1) = Resources.door) or
    (level.getTile(x, y + 1) = Resources.window) then
    d := false;

  if (level.getTile(x - 1, y) = Resources.door) or
    (level.getTile(x - 1, y) = Resources.window) then
    l := false;

  if (level.getTile(x + 1, y) = Resources.door) or
    (level.getTile(x + 1, y) = Resources.window) then
    r := false;

  if (not u) and (not l) then
  begin
    if (not ul) then
      screen.render(x * 16 + 0, y * 16 + 0, 24, col, 0)
    else
      screen.render(x * 16 + 0, y * 16 + 0, 28 + 0 * 32, transitionColor, 3);
  end
  else
  begin
    if l then
      lt := 23
    else
      lt := 22;
    if u then
      ut := 2
    else
      ut := 1;
    screen.render(x * 16 + 0, y * 16 + 0, lt + ut * 32, transitionColor, 3);
  end;

  if (not u) and (not r) then
  begin
    if (not ur) then
      screen.render(x * 16 + 8, y * 16 + 0, 25, col, 0)
    else
      screen.render(x * 16 + 8, y * 16 + 0, 29 + 0 * 32, transitionColor, 3);
  end
  else
  begin
    if r then
      lt := 21
    else
      lt := 22;
    if u then
      ut := 2
    else
      ut := 1;

    screen.render(x * 16 + 8, y * 16 + 0, lt + ut * 32, transitionColor, 3);
  end;

  if (not d) and (not l) then
  begin
    if (not dl) then
      screen.render(x * 16 + 0, y * 16 + 8, 26, col, 0)
    else
      screen.render(x * 16 + 0, y * 16 + 8, 28 + 1 * 32, transitionColor, 3);
  end
  else
  begin
    if l then
      lt := 23
    else
      lt := 22;
    if d then
      ut := 0
    else
      ut := 1;

    screen.render(x * 16 + 0, y * 16 + 8, lt + ut * 32, transitionColor, 3);
  end;

  if (not d) and (not r) then
  begin
    if (not dr) then
      screen.render(x * 16 + 8, y * 16 + 8, 27, col, 0)
    else
      screen.render(x * 16 + 8, y * 16 + 8, 29 + 1 * 32, transitionColor, 3);
  end
  else
  begin
    if r then
      lt := 21
    else
      lt := 22;
    if d then
      ut := 0
    else
      ut := 1;

    screen.render(x * 16 + 8, y * 16 + 8, lt + ut * 32, transitionColor, 3);
  end;
end;

function TWoodenWallTile.mayPass(level: TLevel; x, y: integer;
e: TEntity): Boolean;
begin
  Result := false;
end;

procedure TWoodenWallTile.hurt(level: TLevel; x, y: integer;
Source: TLivingEntity; dmg, attackDir: integer);
begin
  hurt(level, x, y, dmg);
end;

function TWoodenWallTile.interact(level: TLevel; xt, yt: integer;
player: TPlayer; item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  Result := false;
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.axe) then
    begin
      if (player.payStamina(4 - Tool.level)) then
      begin
        hurt(level, xt, yt, random(10) + (Tool.level) * 5 + 10);
        Result := true;
        exit;
      end;
    end;
  end;
end;

procedure TWoodenWallTile.hurt(level: TLevel; x, y, dmg: integer);
var
  i, damage, count: integer;
begin
  damage := level.getData(x, y) + dmg;
  level.add(TSmashParticle.create(x * 16 + 8, y * 16 + 8));
  level.add(TTextParticle.create(inttostr(dmg), x * 16 + 8, y * 16 + 8,
    CalcColor(-1, 500, 500, 500)));
  if (damage >= 20) then
  begin
    count := random(2);
    for i := 0 to count - 1 do
    begin
      level.add(TItemEntity.create(TResourceItem.create(Resources.res_wood),
        x * 16 + random(10) + 3, y * 16 + random(10) + 3));
    end;
    level.setTile(x, y, Resources.dirt, 0);
  end
  else
    level.setData(x, y, damage);
end;

procedure TWoodenWallTile.Tick(level: TLevel; xt, yt: integer);
var
  damage: integer;
begin
  damage := level.getData(xt, yt);
  if (damage > 0) then
    level.setData(xt, yt, damage - 1);
end;

function TWoodenWallTile.getFireFuelAmount(level: TLevel;
xt, yt: integer): integer;
begin
  Result := 20 - level.getData(xt, yt);
end;

procedure TWoodenWallTile.burnFireFuel(level: TLevel;
xt, yt, burnPower: integer; ent: TEntity);
var
  damage: integer;
begin
  damage := level.getData(xt, yt) + burnPower;
  if (damage >= 20) then
    level.setTile(xt, yt, Resources.dirt, 0)
  else
    level.setData(xt, yt, damage);
end;

{ TDoorTile }

constructor TDoorTile.create(id: integer);
begin
  create(id, Resources.dirt);
end;

constructor TDoorTile.create(id: integer; onType: TTile);
begin
  inherited create(id);
  FOnType := onType;
  connectsToSand := onType.connectsToSand;
  connectsToGrass := onType.connectsToGrass;
  connectsToWater := onType.connectsToWater;
  connectsToLava := onType.connectsToLava;
  connectsToPavement := onType.connectsToPavement;
end;

procedure TDoorTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  color: Cardinal;
  o: integer;
begin
  FOnType.render(screen, level, x, y);
  color := CalcColor(100, 421, 532, 553);
  if level.getData(x, y) and OPENED_FLAG > 0 then
    o := 2
  else
    o := 0;
  screen.render(x * 16 + 0, y * 16 + 0, 19 + (1 + o) * 32, color, 0);
  screen.render(x * 16 + 8, y * 16 + 0, 20 + (1 + o) * 32, color, 0);
  screen.render(x * 16 + 0, y * 16 + 8, 19 + (2 + o) * 32, color, 0);
  screen.render(x * 16 + 8, y * 16 + 8, 20 + (2 + o) * 32, color, 0);
end;

function TDoorTile.interact(level: TLevel; xt, yt: integer; player: TPlayer;
item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  // deconstruct with axe
  Result := false;
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.axe) then
    begin
      level.setTile(xt, yt, FOnType, 0);
      level.add(TItemEntity.create(TResourceItem.create(Resources.res_door),
        (xt shl 4) + random(11) - 5, (yt shl 4) + random(11) - 5));
      Result := true;
    end;
  end;
end;

function TDoorTile.use(level: TLevel; xt: integer; yt: integer; player: TPlayer;
attackDir: integer): Boolean;
begin
  // open / close
  level.setData(xt, yt, (level.getData(xt, yt) xor OPENED_FLAG));
  Result := true;
end;

procedure TDoorTile.hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
dmg, attackDir: integer);
var
  damage, count, i: integer;
begin
  damage := (level.getData(x, y) and HEALTH_MASK) + dmg;
  level.add(TSmashParticle.create(x * 16 + 8, y * 16 + 8));
  level.add(TTextParticle.create(inttostr(dmg), x * 16 + 8, y * 16 + 8,
    CalcColor(-1, 500, 500, 500)));
  if (damage >= 10) then
  begin
    count := random(2) + 1;
    for i := 0 to count - 1 do
    begin
      level.add(TItemEntity.create(TResourceItem.create(Resources.res_wood),
        x * 16 + random(10) + 3, y * 16 + random(10) + 3));
    end;
    level.setTile(x, y, Resources.dirt, 0);
  end
  else
    level.setData(x, y, level.getData(x, y) xor (level.getData(x, y) and
      HEALTH_MASK) + damage);
end;

function TDoorTile.mayPass(level: TLevel; x, y: integer; e: TEntity): Boolean;
begin
  Result := (level.getData(x, y) and OPENED_FLAG) > 0;
end;

function TDoorTile.getFireFuelAmount(level: TLevel; xt, yt: integer): integer;
begin
  Result := 10 - (level.getData(xt, yt) and HEALTH_MASK);
end;

procedure TDoorTile.burnFireFuel(level: TLevel; xt: integer; yt: integer;
burnPower: integer; ent: TEntity);
var
  damage: integer;
begin
  damage := (level.getData(xt, yt) and HEALTH_MASK) + burnPower;
  if (damage >= 10) then
    level.setTile(xt, yt, Resources.dirt, 0)
  else
    level.setData(xt, yt, (level.getData(xt, yt) xor (level.getData(xt, yt) and
      HEALTH_MASK)) + damage);
end;

{ TFenceTile }

procedure TFenceTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  col, transitionColor: Cardinal;
  u, d, l, r: Boolean;
  ul, dl, ur, dr: Boolean;

  li, ui: integer;
begin
  col := CalcColor(310, 420, 530, 333);
  transitionColor := CalcColor(310, 420, 530, level.dirtcolor);

  u := level.getTile(x, y - 1) <> self;
  d := level.getTile(x, y + 1) <> self;
  l := level.getTile(x - 1, y) <> self;
  r := level.getTile(x + 1, y) <> self;

  ul := level.getTile(x - 1, y - 1) <> self;
  dl := level.getTile(x - 1, y + 1) <> self;
  ur := level.getTile(x + 1, y - 1) <> self;
  dr := level.getTile(x + 1, y + 1) <> self;

  if (not u) and (not l) then
  begin
    if (not ul) then
      screen.render(x * 16 + 0, y * 16 + 0, 24 + 3 * 32, col, 0)
    else
      screen.render(x * 16 + 0, y * 16 + 0, 28 + 3 * 32, transitionColor, 3);
  end
  else
  begin
    if l then
      li := 23
    else
      li := 22;
    if u then
      ui := 2 + 3
    else
      ui := 1 + 3;
    screen.render(x * 16 + 0, y * 16 + 0, li + ui * 32, transitionColor, 3);
  end;

  if (not u) and (not r) then
  begin
    if (not ur) then
      screen.render(x * 16 + 8, y * 16 + 0, 25 + 3 * 32, col, 0)
    else
      screen.render(x * 16 + 8, y * 16 + 0, 29 + 3 * 32, transitionColor, 3);
  end
  else
  begin
    if r then
      li := 21
    else
      li := 22;
    if u then
      ui := 2 + 3
    else
      ui := 1 + 3;
    screen.render(x * 16 + 8, y * 16 + 0, li + ui * 32, transitionColor, 3);
  end;

  if (not d) and (not l) then
  begin
    if (not dl) then
      screen.render(x * 16 + 0, y * 16 + 8, 26 + 3 * 32, col, 0)
    else
      screen.render(x * 16 + 0, y * 16 + 8, 28 + (1 + 3) * 32,
        transitionColor, 3);
  end
  else
  begin
    if l then
      li := 23
    else
      li := 22;
    if d then
      ui := 0 + 3
    else
      ui := 1 + 3;
    screen.render(x * 16 + 0, y * 16 + 8, li + ui * 32, transitionColor, 3);
  end;

  if (not d) and (not r) then
  begin
    if (not dr) then
      screen.render(x * 16 + 8, y * 16 + 8, 27 + 3 * 32, col, 0)
    else
      screen.render(x * 16 + 8, y * 16 + 8, 29 + (1 + 3) * 32,
        transitionColor, 3);
  end
  else
  begin
    if r then
      li := 21
    else
      li := 22;
    if d then
      ui := 0 + 3
    else
      ui := 1 + 3;

    screen.render(x * 16 + 8, y * 16 + 8, li + ui * 32, transitionColor, 3);
  end;
end;

procedure TFenceTile.hurt(level: TLevel; x, y: integer; Source: TLivingEntity;
dmg, attackDir: integer);
begin
  hurt(level, x, y, dmg);
end;

function TFenceTile.interact(level: TLevel; xt, yt: integer; player: TPlayer;
item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  Result := false;
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.axe) then
    begin
      if (player.payStamina(4 - Tool.level)) then
      begin
        hurt(level, xt, yt, random(10) + (Tool.level) * 5 + 10);
        Result := true;
      end;
    end;
  end;
end;

function TFenceTile.mayPass(level: TLevel; x, y: integer; e: TEntity): Boolean;
begin
  Result := false;
end;

procedure TFenceTile.hurt(level: TLevel; x, y, dmg: integer);
var
  damage, count, i: integer;
begin
  damage := level.getData(x, y) + dmg;
  level.add(TSmashParticle.create(x * 16 + 8, y * 16 + 8));
  level.add(TTextParticle.create(inttostr(dmg), x * 16 + 8, y * 16 + 8,
    CalcColor(-1, 500, 500, 500)));
  if (damage >= 10) then
  begin
    count := random(2);
    for i := 0 to count - 1 do
    begin
      level.add(TItemEntity.create(TResourceItem.create(Resources.res_wood),
        x * 16 + random(10) + 3, y * 16 + random(10) + 3));
    end;
    level.setTile(x, y, Resources.dirt, 0);
  end
  else
    level.setData(x, y, damage);
end;

function TFenceTile.getVisibilityBlocking(level: TLevel; x: integer; y: integer;
e: TEntity): integer;
begin
  Result := 20;
end;

function TFenceTile.getFireFuelAmount(level: TLevel; xt: integer;
yt: integer): integer;
begin
  Result := 10 - level.getData(xt, yt);
end;

procedure TFenceTile.burnFireFuel(level: TLevel; xt: integer; yt: integer;
burnPower: integer; ent: TEntity);
var
  damage: integer;
begin
  damage := level.getData(xt, yt) + burnPower;
  if (damage >= 10) then
    level.setTile(xt, yt, Resources.dirt, 0)
  else
    level.setData(xt, yt, damage);
end;

{ TRockWallTile }

constructor TRockWallTile.create(id: integer);
begin
  inherited create(id);
  connectsToPavement := true
end;

function TRockWallTile.mayPass(level: TLevel; x, y: integer;
e: TEntity): Boolean;
begin
  Result := false;
end;

procedure TRockWallTile.render(screen: TScreen; level: TLevel; x, y: integer);
var
  col, transitionColor: cardinal;
  u, d, l, r: Boolean;
  ul, dl, ur, dr: Boolean;
  li, ui: integer;
begin
  col := CalcColor(111, 444, 555, 333);
  transitionColor := CalcColor(111, 444, 555, level.dirtcolor);

  u := level.getTile(x, y - 1) <> self;
  d := level.getTile(x, y + 1) <> self;
  l := level.getTile(x - 1, y) <> self;
  r := level.getTile(x + 1, y) <> self;

  ul := level.getTile(x - 1, y - 1) <> self;
  dl := level.getTile(x - 1, y + 1) <> self;
  ur := level.getTile(x + 1, y - 1) <> self;
  dr := level.getTile(x + 1, y + 1) <> self;

  // attach to door
  if (level.getTile(x, y - 1) = Resources.door) or
    (level.getTile(x, y - 1) = Resources.window) then
    u := false;

  if (level.getTile(x, y + 1) = Resources.door) or
    (level.getTile(x, y + 1) = Resources.window) then
    d := false;

  if (level.getTile(x - 1, y) = Resources.door) or
    (level.getTile(x - 1, y) = Resources.window) then
    l := false;

  if (level.getTile(x + 1, y) = Resources.door) or
    (level.getTile(x + 1, y) = Resources.window) then
    r := false;

  if (not u) and (not l) then
  begin
    if (not ul) then
      screen.render(x * 16 + 0, y * 16 + 0, 24, col, 0)
    else
      screen.render(x * 16 + 0, y * 16 + 0, 28 + 0 * 32, transitionColor, 3);
  end
  else
  begin
    if l then
      li := 23
    else
      li := 22;
    if u then
      ui := 2
    else
      ui := 1;

    screen.render(x * 16 + 0, y * 16 + 0, li + ui * 32, transitionColor, 3);
  end;

  if (not u) and (not r) then
  begin
    if (not ur) then
      screen.render(x * 16 + 8, y * 16 + 0, 25, col, 0)
    else
      screen.render(x * 16 + 8, y * 16 + 0, 29 + 0 * 32, transitionColor, 3);
  end
  else
  begin
    if r then
      li := 21
    else
      li := 22;
    if u then
      ui := 2
    else
      ui := 1;

    screen.render(x * 16 + 8, y * 16 + 0, li + ui * 32, transitionColor, 3);
  end;

  if (not d) and (not l) then
  begin
    if (not dl) then
      screen.render(x * 16 + 0, y * 16 + 8, 26, col, 0)
    else
      screen.render(x * 16 + 0, y * 16 + 8, 28 + 1 * 32, transitionColor, 3);
  end
  else
  begin
    if l then
      li := 23
    else
      li := 22;
    if d then
      ui := 0
    else
      ui := 1;

    screen.render(x * 16 + 0, y * 16 + 8, li + ui * 32, transitionColor, 3);
  end;

  if (not d) and (not r) then
  begin
    if (not dr) then
      screen.render(x * 16 + 8, y * 16 + 8, 27, col, 0)
    else
      screen.render(x * 16 + 8, y * 16 + 8, 29 + 1 * 32, transitionColor, 3);
  end
  else
  begin
    if r then
      li := 21
    else
      li := 22;
    if d then
      ui := 0
    else
      ui := 1;
    screen.render(x * 16 + 8, y * 16 + 8, li + ui * 32, transitionColor, 3);
  end;
end;

procedure TRockWallTile.hurt(level: TLevel; x: integer; y: integer;
Source: TLivingEntity; dmg: integer; attackDir: integer);
begin
  hurt(level, x, y, dmg);
end;

function TRockWallTile.interact(level: TLevel; xt: integer; yt: integer;
player: TPlayer; item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  Result := false;
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.pickaxe) then
    begin
      if (player.payStamina(4 - Tool.level)) then
      begin
        hurt(level, xt, yt, random(10) + (Tool.level) * 5 + 10);
        Result := true;
      end;
    end;
  end;
end;

procedure TRockWallTile.hurt(level: TLevel; x: integer; y: integer;
dmg: integer);
var
  damage, count, i: integer;
begin
  damage := level.getData(x, y) + dmg;
  level.add(TSmashParticle.create(x * 16 + 8, y * 16 + 8));
  level.add(TTextParticle.create(inttostr(dmg), x * 16 + 8, y * 16 + 8,
    CalcColor(-1, 500, 500, 500)));
  if (damage >= 50) then
  begin
    count := random(2);
    for i := 0 to count - 1 do
      level.add(TItemEntity.create(TResourceItem.create(Resources.res_stone),
        x * 16 + random(10) + 3, y * 16 + random(10) + 3));
    level.setTile(x, y, Resources.dirt, 0);
  end
  else
    level.setData(x, y, damage);
end;

procedure TRockWallTile.Tick(level: TLevel; xt: integer; yt: integer);
var
  damage: integer;
begin
  damage := level.getData(xt, yt);
  if (damage > 0) then
    level.setData(xt, yt, damage - 1);
end;

{ TWindowTile }

constructor TWindowTile.create(id: integer);
begin
  create(id, Resources.dirt);
end;

constructor TWindowTile.create(id: integer; onType: TTile);
begin
  inherited create(id);
  FOnType := onType;
  FOpened := false;
  FLocked := false;
  connectsToSand := onType.connectsToSand;
  connectsToGrass := onType.connectsToGrass;
  connectsToWater := onType.connectsToWater;
  connectsToLava := onType.connectsToLava;
  connectsToPavement := onType.connectsToPavement;

end;

procedure TWindowTile.render(screen: TScreen; level: TLevel; x: integer;
y: integer);
var
  color: Cardinal;
begin
  FOnType.render(screen, level, x, y);
  color := CalcColor(100, 421, 532, 345);
  screen.render(x * 16 + 0, y * 16 + 0, 17 + (3) * 32, color, 0);
  screen.render(x * 16 + 8, y * 16 + 0, 18 + (3) * 32, color, 0);
  screen.render(x * 16 + 0, y * 16 + 8, 17 + (4) * 32, color, 0);
  screen.render(x * 16 + 8, y * 16 + 8, 18 + (4) * 32, color, 0);

end;

function TWindowTile.interact(level: TLevel; xt: integer; yt: integer;
player: TPlayer; item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  Result := false;
  if (item is TToolItem) then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.axe) then
    begin
      level.setTile(xt, yt, FOnType, 0);
      level.add(TItemEntity.create(TResourceItem.create(Resources.res_window),
        (xt shl 4) + random(11) - 5, (yt shl 4) + random(11) - 5));
      Result := true;
    end;
  end;
end;

procedure TWindowTile.hurt(level: TLevel; x: integer; y: integer;
Source: TLivingEntity; dmg: integer; attackDir: integer);
var
  damage: integer;
begin
  damage := level.getData(x, y) + dmg;
  level.add(TSmashParticle.create(x * 16 + 8, y * 16 + 8));
  level.add(TTextParticle.create(inttostr(dmg), x * 16 + 8, y * 16 + 8,
    CalcColor(-1, 500, 500, 500)));
  if (damage >= 10) then
    level.setTile(x, y, FOnType, 0)
  else
    level.setData(x, y, damage);
end;

function TWindowTile.getVisibilityBlocking(level: TLevel; x, y: integer;
e: TEntity): integer;
begin
  Result := 10;
end;

function TWindowTile.getFireFuelAmount(level: TLevel; xt, yt: integer): integer;
begin
  Result := 10 - level.getData(xt, yt);
end;

procedure TWindowTile.burnFireFuel(level: TLevel; xt, yt, burnPower: integer;
ent: TEntity);
var
  damage: integer;
begin
  damage := level.getData(xt, yt) + burnPower;
  if (damage >= 10) then
    level.setTile(xt, yt, Resources.dirt, 0)
  else
    level.setData(xt, yt, damage);
end;

{ TRockFloorTile }

constructor TRockFloorTile.create(id: integer);
begin
  inherited create(id);
  connectsToPavement := true;
end;

procedure TRockFloorTile.render(screen: TScreen; level: TLevel; x: integer;
y: integer);
var
  baseCol, col, transitionColor: Cardinal;
  u, d, l, r: Boolean;
  li, ui: integer;
begin
  baseCol := (((level.grasscolor - (level.grasscolor div 100) * 100) div 10)
    - 1) * 111;
  col := CalcColor(baseCol, baseCol, baseCol + 111, baseCol + 111);
  transitionColor := CalcColor(baseCol - 111, baseCol, baseCol + 111,
    level.dirtcolor);

  u := not level.getTile(x, y - 1).connectsToPavement;
  d := not level.getTile(x, y + 1).connectsToPavement;
  l := not level.getTile(x - 1, y).connectsToPavement;
  r := not level.getTile(x + 1, y).connectsToPavement;

  if (not u) and (not l) then
    screen.render(x * 16 + 0, y * 16 + 0, 24, col, 0)
  else
  begin
    if l then
      li := 11
    else
      li := 12;
    if u then
      ui := 0
    else
      ui := 1;

    screen.render(x * 16 + 0, y * 16 + 0, li + ui * 32, transitionColor, 0);
  end;

  if (not u) and (not r) then
    screen.render(x * 16 + 8, y * 16 + 0, 25, col, 0)
  else
  begin
    if r then
      li := 13
    else
      li := 12;
    if u then
      ui := 0
    else
      ui := 1;

    screen.render(x * 16 + 8, y * 16 + 0, li + ui * 32, transitionColor, 0);
  end;

  if (not d) and (not l) then
    screen.render(x * 16 + 0, y * 16 + 8, 26, col, 0)
  else
  begin
    if l then
      li := 11
    else
      li := 12;
    if d then
      ui := 2
    else
      ui := 1;

    screen.render(x * 16 + 0, y * 16 + 8, li + ui * 32, transitionColor, 0);
  end;
  if (not d) and (not r) then
    screen.render(x * 16 + 8, y * 16 + 8, 27, col, 0)
  else
  begin
    if r then
      li := 13
    else
      li := 12;
    if d then
      ui := 2
    else
      ui := 1;

    screen.render(x * 16 + 8, y * 16 + 8, li + ui * 32, transitionColor, 0);
  end;
end;

function TRockFloorTile.interact(level: TLevel; xt, yt: integer;
player: TPlayer; item: TItem; attackDir: integer): Boolean;
var
  Tool: TToolItem;
begin
  Result := false;
  if item is TToolItem then
  begin
    Tool := TToolItem(item);
    if (Tool.typ = Tooltypes.pickaxe) then
    begin
      if (player.payStamina(4 - Tool.level)) then
      begin
        level.setTile(xt, yt, Resources.dirt, 0);
        level.add(TItemEntity.create(TResourceItem.create(Resources.res_stone),
          xt * 16 + random(10) + 3, yt * 16 + random(10) + 3));
        Sound.Play(seMonsterHurt);
        Result := true;
      end;
    end;
  end;
end;

// --  Entities -----------------------------------------------------------------

constructor TEntity.create;
begin
  xr := 6;
  yr := 6;
end;

procedure TEntity.render(screen: TScreen);
begin
end;

procedure TEntity.Tick();
begin
end;

procedure TEntity.remove();
begin
  removed := true;
end;

procedure TEntity.init(level: TLevel);
begin
  self.level := level;
end;

function TEntity.intersects(const x0, y0, x1, y1: integer): Boolean;
begin
  Result := not((x + xr < x0) or (y + yr < y0) or (x - xr > x1) or
    (y - yr > y1));
end;

function TEntity.blocks(e: TEntity): Boolean;
begin
  Result := false;
end;

procedure TEntity.hurt(mob: TLivingEntity; const dmg, attackDir: integer);
begin
end;

procedure TEntity.hurt(tile: TTile; const x, y, dmg: integer);
begin
end;

function TEntity.move(xa, ya: integer): Boolean;
var
  stopped: Boolean;
  xt, yt: integer;
begin
  Result := true;
  if (xa <> 0) or (ya <> 0) then
  begin
    stopped := true;
    if (xa <> 0) and (move2(xa, 0)) then
      stopped := false;
    if (ya <> 0) and (move2(0, ya)) then
      stopped := false;
    if (not stopped) then
    begin
      xt := x shr 4;
      yt := y shr 4;
      level.getTile(xt, yt).steppedOn(level, xt, yt, self);
    end;
    Result := not stopped;
  end;
end;

function TEntity.move2(xa, ya: integer): Boolean;
var
  xt0, yt0, xt1, yt1: integer;
  xto0, yto0, xto1, yto1: integer;
  xt, yt: integer;
  isInside, wasInside: TEntityList;
  i: integer;
  e: TEntity;

  procedure RemoveList(const Source, target: TEntityList);
  var
    i, j: integer;
  begin
    for i := Source.count - 1 downto 0 do
      for j := 0 to target.count - 1 do
        if Source[i] = target[j] then
        begin
          Source.Delete(i);
          break;
        end;
  end;

begin
  Result := true;

  xto0 := ((x) - xr) shr 4;
  yto0 := ((y) - yr) shr 4;
  xto1 := ((x) + xr) shr 4;
  yto1 := ((y) + yr) shr 4;

  xt0 := ((x + xa) - xr) shr 4;
  yt0 := ((y + ya) - yr) shr 4;
  xt1 := ((x + xa) + xr) shr 4;
  yt1 := ((y + ya) + yr) shr 4;

  for yt := yt0 to yt1 do
    for xt := xt0 to xt1 do
    begin
      if (xt >= xto0) and (xt <= xto1) and (yt >= yto0) and (yt <= yto1) then
        continue;
      level.getTile(xt, yt).bumpedInto(level, xt, yt, self);
      if (not level.getTile(xt, yt).mayPass(level, xt, yt, self)) then
      begin
        Result := false;
        exit;
      end;
    end;

  wasInside := level.getEntities(x - xr, y - yr, x + xr, y + yr);
  isInside := level.getEntities(x + xa - xr, y + ya - yr, x + xa + xr,
    y + ya + yr);

  try
    for i := 0 to isInside.count - 1 do
    begin
      e := isInside[i];
      if (e <> self) then
        e.touchedBy(self);
    end;

    RemoveList(isInside, wasInside);
    for i := 0 to isInside.count - 1 do
    begin
      e := isInside[i];
      if (e <> self) and (e.blocks(self)) then
      begin
        Result := false;
        exit;
      end;
    end;

    x := x + xa;
    y := y + ya;
  finally
    isInside.Free;
    wasInside.Free;
  end;
end;

procedure TEntity.touchedBy(entity: TEntity);
begin
end;

function TEntity.isBlockableBy(mob: TMob): Boolean;
begin
  Result := true;
end;

procedure TEntity.touchItem(ItemEntity: TItemEntity);
begin
end;

function TEntity.canSwim(): Boolean;
begin
  Result := false;
end;

function TEntity.interact(player: TPlayer; item: TItem;
attackDir: integer): Boolean;
begin
  Result := item.interact(player, self, attackDir);
end;

function TEntity.use(player: TPlayer; attackDir: integer): Boolean;
begin
  Result := false;
end;

function TEntity.getLightRadius(): integer;
begin
  Result := 0;
end;

function TEntity.distanceFrom(entity: TEntity): integer;
begin
  if (entity = nil) then
    Result := -1
  else
    Result := abs(x - entity.x) + abs(y - entity.y);
end;

{ TItemEntity }

constructor TItemEntity.create(item: TItem; x, y: integer);
begin
  inherited create;
  walkDist := 0;
  dir := 0;
  hurtTime := 0;
  time := 0;

  self.item := item;
  xx := x;
  self.x := x;

  yy := y;
  self.y := y;

  xr := 3;
  yr := 3;

  zz := 2;
  xa := RandomGaussian() * 0.3;
  ya := RandomGaussian() * 0.2;
  za := RandomFloat * 0.7 + 1;

  lifeTime := 60 * 10 + random(60);
end;

destructor TItemEntity.Destroy;
begin
  FreeAndNil(item);
  inherited;
end;

procedure TItemEntity.Tick;
var
  ox, oy, nx, ny: integer;
  expectedx, expectedy: integer;
  gotx, goty: integer;
begin
  inc(time);
  if (time >= lifeTime) then
  begin
    remove();
    exit;
  end;
  xx := xx + xa;
  yy := yy + ya;
  zz := zz + za;
  if (zz < 0) then
  begin
    zz := 0;
    za := za * -0.5;
    xa := xa * 0.6;
    ya := ya * 0.6;
  end;
  za := za - 0.15;
  ox := x;
  oy := y;
  nx := Trunc(xx);
  ny := Trunc(yy);
  expectedx := nx - x;
  expectedy := ny - y;
  move(nx - x, ny - y);
  gotx := x - ox;
  goty := y - oy;
  xx := xx + (gotx - expectedx);
  yy := yy + (goty - expectedy);

  if (hurtTime > 0) then
    dec(hurtTime);
end;

function TItemEntity.isBlockableBy(mob: TMob): Boolean;
begin
  Result := false;
end;

procedure TItemEntity.render(screen: TScreen);
begin
  if (time >= lifeTime - 6 * 20) then
    if ((time div 6) mod 2 = 0) then
      exit;

  screen.render(x - 4, y - 4, item.getSprite(), CalcColor(-1, 0, 0, 0), 0);
  screen.render(x - 4, y - 4 - Trunc(zz), item.getSprite, item.getColor(), 0);
end;

procedure TItemEntity.touchedBy(entity: TEntity);
begin
  if (time > 30) then
    entity.touchItem(self);
end;

procedure TItemEntity.take(player: TPlayer);
begin
  Sound.Play(sepickup);
  inc(player.score);
  item.onTake(self);
  remove();
end;

{ TLivingEntity }

constructor TLivingEntity.create;
begin
  inherited;
  walkDist := 0;
  dir := 0;
  hurtTime := 0;
  maxHealth := 10;
  health := maxHealth;
  swimTimer := 0;
  tickTime := 0;
  karma := 0;
end;

procedure TLivingEntity.Tick;
begin
  inc(tickTime);
  if (level.getTile(x shr 4, y shr 4) = Resources.lava) then
    hurt(self, 4, dir xor 1);

  if (health <= 0) then
    die();
  if (hurtTime > 0) then
    dec(hurtTime);
end;

procedure TLivingEntity.die;
begin
  remove();
end;

function TLivingEntity.move(xa: integer; ya: integer): Boolean;
begin
  if (isSwimming()) then
  begin
    inc(swimTimer);
    if (swimTimer mod 2 = 0) then
    begin
      Result := true;
      exit;
    end;
  end;

  if (xKnockback < 0) then
  begin
    move2(-1, 0);
    inc(xKnockback);
  end;

  if (xKnockback > 0) then
  begin
    move2(1, 0);
    dec(xKnockback);
  end;

  if (yKnockback < 0) then
  begin
    move2(0, -1);
    inc(yKnockback);
  end;

  if (yKnockback > 0) then
  begin
    move2(0, 1);
    dec(yKnockback);
  end;

  if (hurtTime > 0) then
  begin
    Result := true;
    exit;
  end;

  if (xa <> 0) or (ya <> 0) then
  begin
    inc(walkDist);
    if (xa < 0) then
      dir := 2;
    if (xa > 0) then
      dir := 3;
    if (ya < 0) then
      dir := 1;
    if (ya > 0) then
      dir := 0;
  end;
  Result := inherited move(xa, ya);
end;

function TLivingEntity.isSwimming;
var
  tile: TTile;
begin
  tile := level.getTile(x shr 4, y shr 4);
  Result := (tile = Resources.water) or (tile = Resources.lava);
end;

procedure TLivingEntity.hurt(tile: TTile; const x, y, dmg: integer);
var
  attackDir: integer;
begin
  attackDir := dir xor 1;
  doHurt(dmg, attackDir);
end;

procedure TLivingEntity.hurt(mob: TLivingEntity; const dmg: integer;
const attackDir: integer);
var
  minKarma: integer;
begin
  doHurt(dmg, attackDir);
  // change attackers karma
  if karma > 0 then
    minKarma := 1
  else if karma < 0 then
    minKarma := -1
  else
    minKarma := 0;

  mob.karma := mob.karma - (karma * dmg div 1000) + minKarma;
end;

procedure TLivingEntity.heal(heal: integer);
begin
  if (hurtTime > 0) then
    exit;

  level.add(TTextParticle.create(inttostr(heal), x, y, CalcColor(-1, 50,
    50, 50)));
  health := health + heal;
  if (health > maxHealth) then
    health := maxHealth;
end;

procedure TLivingEntity.doHurt(damage: integer; attackDir: integer);
var
  xd, yd: integer;
begin
  if (hurtTime > 0) then
    exit;

  if (level.player <> nil) then
  begin
    xd := level.player.x - x;
    yd := level.player.y - y;
    if (xd * xd + yd * yd < 80 * 80) then
      Sound.Play(seMonsterHurt);
  end;

  level.add(TTextParticle.create(inttostr(damage), x, y, CalcColor(-1, 500,
    500, 500)));
  dec(health, damage);
  if attackDir = 0 then
    yKnockback := +6;
  if attackDir = 1 then
    yKnockback := -6;
  if attackDir = 2 then
    xKnockback := -6;
  if attackDir = 3 then
    xKnockback := +6;
  hurtTime := 10;
end;

function TLivingEntity.findStartPos(level: TLevel): Boolean;
var
  r, x, y, xx, yy, xd, yd: integer;
  List: TEntityList;
begin
  Result := false;
  x := random(level.w);
  y := random(level.h);
  xx := x * 16 + 8;
  yy := y * 16 + 8;

  if (level.player <> nil) then
  begin
    xd := level.player.x - xx;
    yd := level.player.y - yy;
    if (xd * xd + yd * yd < 80 * 80) then
      exit;
  end;

  r := level.monsterDensity * 16;
  List := level.getEntities(xx - r, yy - r, xx + r, yy + r);
  if (List.count = 0) and (level.getTile(x, y).mayPass(level, x, y, self)) then
  begin
    self.x := xx;
    self.y := yy;
    Result := true;
  end;
  List.Free;
end;

function TLivingEntity.getFacingTileX: integer;
var
  xa: integer;
begin
  if (dir = 2) then
    xa := -1
  else if (dir = 3) then
    xa := 1
  else
    xa := 0;

  Result := (x shr 4) + xa;
end;

function TLivingEntity.getFacingTileY: integer;
var
  ya: integer;
begin
  if dir = 1 then
    ya := -1
  else if dir = 0 then
    ya := 1
  else
    ya := 0;
  Result := (y shr 4) + ya;
end;

function TLivingEntity.getFacingTile: TTile;
var
  xt, yt: integer;
begin
  xt := getFacingTileX();
  yt := getFacingTileY();
  Result := level.getTile(xt, yt);
end;

function TLivingEntity.getKarma: integer;
begin
  Result := karma;
end;

function TLivingEntity.isGood: Boolean;
begin
  Result := karma > 100;
end;

function TLivingEntity.isEvil: Boolean;
begin
  Result := karma < -100;
end;

function TLivingEntity.isNeutral: Boolean;
begin
  Result := (not isGood) and (not isEvil);
end;

{ TMob }

constructor TMob.create;
begin
  inherited;
  karma := -100;
  x := 8;
  y := 8;
  xr := 4;
  yr := 3;
end;

function TMob.blocks(e: TEntity): Boolean;
begin
  Result := e.isBlockableBy(self)
end;

{ TNPC }

constructor TNPC.create;
begin
  inherited;
  x := 8;
  y := 8;
  xr := 4;
  yr := 3;
end;

{ TWanderer }

constructor TWanderer.create(lvl: integer);
begin
  inherited create;
  randomWalkTime := 0;
  idleTime := 0;
  self.lvl := lvl;
  x := random(64 * 16);
  y := random(64 * 16);
  maxHealth := lvl * lvl * 10;
  health := maxHealth;
end;

procedure TWanderer.Tick;
var
  speed: integer;
  xt, yt: integer;
  tile: TTile;
  count, i: integer;
begin
  inherited;

  if (randomWalkTime > 0) then
  begin
    dec(randomWalkTime);
    idleTime := 0;
  end
  else
  begin
    i := random(100);
    if i < 10 then
      xa := -1
    else if i > 90 then
      xa := 1
    else
      xa := 0;

    i := random(100);
    if i < 10 then
      ya := -1
    else if i > 90 then
      ya := 1
    else
      ya := 0;

    inc(idleTime);
  end;

  // random walking
  speed := tickTime and 1;
  if (not move(xa * speed, ya * speed)) or (random(200) = 0) then
  begin
    randomWalkTime := random(500) + 50;
    xa := (random(3) - 1) * random(2);
    ya := (random(3) - 1) * random(2);
  end;
  if (randomWalkTime > 0) then
    dec(randomWalkTime);

  // random building
  if (idleTime > 200) and (random(800) = 0) then
  begin
    xt := getFacingTileX();
    yt := getFacingTileY();
    // build if you can
    tile := level.getTile(xt, yt);
    if (tile = Resources.grass) or (tile = Resources.dirt) then
    begin
      level.setTile(xt, yt, Resources.woodenWall, 0);
    end;
    idleTime := 0;
  end;

  // random destruction
  if (idleTime > 200) and (random(1000) = 0) then
  begin
    tile := getFacingTile();
    if (tile = Resources.woodenWall) then
    begin
      xt := getFacingTileX();
      yt := getFacingTileY();
      level.setTile(xt, yt, Resources.dirt, 0);
      count := random(2);
      for i := 0 to count - 1 do
      begin
        level.add(TItemEntity.create(TResourceItem.create(Resources.res_wood),
          xt * 16 + random(10) + 3, yt * 16 + random(10) + 3));
      end;

      if (level.player <> nil) and
        (distanceFrom(level.player) < HEARING_DISTANCE) then
        Sound.Play(secraft);
      idleTime := 0;
    end;
  end;

  // random cutting down trees
  if (idleTime > 100) and (random(300) = 0) then
  begin
    tile := getFacingTile();
    if (tile = Resources.tree) then
    begin
      xt := getFacingTileX();
      yt := getFacingTileY();
      level.setTile(xt, yt, Resources.grass, 0);
      count := random(2);
      for i := 0 to count - 1 do
      begin
        level.add(TItemEntity.create(TResourceItem.create(Resources.res_wood),
          x * 16 + random(10) + 3, y * 16 + random(10) + 3));
      end;
      if (level.player <> nil) and
        (distanceFrom(level.player) < HEARING_DISTANCE) then
        Sound.play(secraft);
      idleTime := 0;
    end;
  end;
end;

procedure TWanderer.render(screen: TScreen);
var
  xt, yt, xo, yo: integer;
  flip1, flip2: integer;
  col: cardinal;
begin
  xt := 0;
  yt := 14;

  flip1 := (walkDist shr 3) and 1;
  flip2 := (walkDist shr 3) and 1;

  if (dir = 1) then
    xt := xt + 2;

  if (dir > 1) then
  begin
    flip1 := 0;
    flip2 := ((walkDist shr 4) and 1);
    if (dir = 2) then
      flip1 := 1;

    xt := xt + 4 + ((walkDist shr 3) and 1) * 2;
  end;

  xo := x - 8;
  yo := y - 11;

  col := CalcColor(-1, 000, 100, 532);
  if (hurtTime > 0) then
    col := CalcColor(-1, 555, 555, 555);

  screen.render(xo + 8 * flip1, yo + 0, xt + yt * 32, col, flip1);
  screen.render(xo + 8 - 8 * flip1, yo + 0, xt + 1 + yt * 32, col, flip1);
  screen.render(xo + 8 * flip2, yo + 8, xt + (yt + 1) * 32, col, flip2);
  screen.render(xo + 8 - 8 * flip2, yo + 8, xt + 1 + (yt + 1) * 32, col, flip2);
end;

procedure TWanderer.touchedBy(entity: TEntity);
var
  mob: TMob;
begin
  if entity is TMob then
  begin
    mob := TMob(entity);
    hurt(mob, mob.lvl + 1, mob.dir);
  end;
end;

procedure TWanderer.die;
var
  count, i: integer;
begin
  inherited;

  // some clothes
  count := random(2) + 1;
  for i := 0 to count - 1 do
    level.add(TItemEntity.create(TResourceItem.create(Resources.res_cloth),
      x + random(11) - 5, y + random(11) - 5));

  // maybe food
  count := random(3);
  for i := 0 to count - 1 do
    level.add(TItemEntity.create(TResourceItem.create(Resources.res_apple),
      x + random(11) - 5, y + random(11) - 5));

  count := random(2);
  for i := 0 to count - 1 do
    level.add(TItemEntity.create(TResourceItem.create(Resources.res_bread),
      x + random(11) - 5, y + random(11) - 5));

  if (level.player <> nil) then
    level.player.score := level.player.score + 100 * lvl;
end;

{ TSlime }

constructor TSlime.create(lvl: integer);
begin
  inherited create;
  jumpTime := 0;
  karma := lvl * (-8);
  self.lvl := lvl;
  x := random(64 * 16);
  y := random(64 * 16);
  maxHealth := lvl * lvl * 5;
  health := maxHealth;
end;

procedure TSlime.Tick();
var
  speed: integer;
  xd, yd: integer;
begin
  inherited;

  speed := 1;
  if (not move(xa * speed, ya * speed)) or (random(40) = 0) then
  begin
    if (jumpTime <= -10) then
    begin
      xa := (random(3) - 1);
      ya := (random(3) - 1);

      if (level.player <> nil) then
      begin
        xd := level.player.x - x;
        yd := level.player.y - y;
        if (xd * xd + yd * yd < 50 * 50) then
        begin
          if (xd < 0) then
            xa := -1;
          if (xd > 0) then
            xa := +1;
          if (yd < 0) then
            ya := -1;
          if (yd > 0) then
            ya := +1;
        end;
      end;

      if (xa <> 0) or (ya <> 0) then
        jumpTime := 10;
    end;
  end;

  dec(jumpTime);
  if (jumpTime = 0) then
  begin
    xa := 0;
    ya := 0;
  end;
end;

procedure TSlime.die();
var
  i, count: integer;
begin
  inherited;

  count := random(2) + 1;
  for i := 0 to count - 1 do
  begin
    level.add(TItemEntity.create(TResourceItem.create(Resources.res_slime),
      x + random(11) - 5, y + random(11) - 5));
  end;

  if (level.player <> nil) then
    level.player.score := level.player.score + 25 * lvl;
end;

procedure TSlime.render(screen: TScreen);
var
  col: Cardinal;
  xt, yt, xo, yo: integer;
begin
  xt := 0;
  yt := 18;

  xo := x - 8;
  yo := y - 11;

  if (jumpTime > 0) then
  begin
    xt := xt + 2;
    yo := yo - 4;
  end;

  col := CalcColor(-1, 10, 252, 555);
  if (lvl = 2) then
    col := CalcColor(-1, 100, 522, 555);
  if (lvl = 3) then
    col := CalcColor(-1, 111, 444, 555);
  if (lvl = 4) then
    col := CalcColor(-1, 000, 111, 224);

  if (hurtTime > 0) then
  begin
    col := CalcColor(-1, 555, 555, 555);
  end;

  screen.render(xo + 0, yo + 0, xt + yt * 32, col, 0);
  screen.render(xo + 8, yo + 0, xt + 1 + yt * 32, col, 0);
  screen.render(xo + 0, yo + 8, xt + (yt + 1) * 32, col, 0);
  screen.render(xo + 8, yo + 8, xt + 1 + (yt + 1) * 32, col, 0);
end;

procedure TSlime.touchedBy(entity: TEntity);
begin
  if (entity is TPlayer) or (entity is TNPC) then
    entity.hurt(self, lvl, dir);
end;

{ TZombie }

constructor TZombie.create(lvl: integer);
begin
  inherited create;
  randomWalkTime := 0;
  karma := lvl * (-10);

  self.lvl := lvl;
  x := random(64 * 16);
  y := random(64 * 16);
  health := lvl * lvl * 10;
  maxHealth := health;
end;

procedure TZombie.Tick();
var
  speed, xd, yd: integer;
begin
  inherited;

  if (level.player <> nil) and (randomWalkTime = 0) then
  begin
    xd := level.player.x - x;
    yd := level.player.y - y;
    if (Cardinal(xd * xd + yd * yd) < 50 * 50) then
    begin
      xa := 0;
      ya := 0;
      if (xd < 0) then
        xa := -1;
      if (xd > 0) then
        xa := +1;
      if (yd < 0) then
        ya := -1;
      if (yd > 0) then
        ya := +1;
    end;
  end;

  speed := tickTime and 1;
  if (not move(xa * speed, ya * speed)) or (random(200) = 0) then
  begin
    randomWalkTime := 60;
    xa := (random(3) - 1) * random(2);
    ya := (random(3) - 1) * random(2);
  end;
  if (randomWalkTime > 0) then
    dec(randomWalkTime);
end;

procedure TZombie.render(screen: TScreen);
var
  flip1, flip2, xt, yt: integer;
  col: Cardinal;
  xo, yo: integer;
begin
  xt := 0;
  yt := 14;

  flip1 := (walkDist shr 3) and 1;
  flip2 := (walkDist shr 3) and 1;

  if (dir = 1) then
  begin
    inc(xt, 2);
  end;

  if (dir > 1) then
  begin
    flip1 := 0;
    flip2 := ((walkDist shr 4) and 1);
    if (dir = 2) then
    begin
      flip1 := 1;
    end;
    xt := xt + (4 + ((walkDist shr 3) and 1) * 2);
  end;

  xo := x - 8;
  yo := y - 11;

  col := CalcColor(-1, 10, 252, 050);
  if (lvl = 2) then
    col := CalcColor(-1, 100, 522, 050);
  if (lvl = 3) then
    col := CalcColor(-1, 111, 444, 050);
  if (lvl = 4) then
    col := CalcColor(-1, 000, 111, 020);
  if (hurtTime > 0) then
    col := CalcColor(-1, 555, 555, 555);

  screen.render(xo + 8 * flip1, yo + 0, xt + yt * 32, col, flip1);
  screen.render(xo + 8 - 8 * flip1, yo + 0, xt + 1 + yt * 32, col, flip1);
  screen.render(xo + 8 * flip2, yo + 8, xt + (yt + 1) * 32, col, flip2);
  screen.render(xo + 8 - 8 * flip2, yo + 8, xt + 1 + (yt + 1) * 32, col, flip2);
end;

procedure TZombie.touchedBy(entity: TEntity);
begin
  if (entity is TPlayer) then
    entity.hurt(self, lvl + 1, dir);
end;

procedure TZombie.die();
var
  i, count: integer;
begin
  inherited;

  count := random(2) + 1;
  for i := 0 to count - 1 do
    level.add(TItemEntity.create(TResourceItem.create(Resources.res_cloth),
      x + random(11) - 5, y + random(11) - 5));

  if (level.player <> nil) then
    level.player.score := level.player.score + 50 * lvl;
end;

{ TAirWizard }

constructor TAirwizard.create;
begin
  inherited;
  randomWalkTime := 0;
  attackDelay := 0;
  attackTime := 0;
  attackType := 0;

  x := random(64 * 16);
  y := random(64 * 16);
  health := 2000;
  maxHealth := health;
end;

procedure TAirwizard.Tick();
var
  fdir, fspeed: single;
  speed, xd, yd: integer;
begin
  inherited;

  if (attackDelay > 0) then
  begin
    dir := ((attackDelay - 45) div 4) mod 4;
    dir := ((dir * 2) mod 4) + (dir div 2);
    if (attackDelay < 45) then
    begin
      dir := 0;
    end;
    dec(attackDelay);
    if (attackDelay = 0) then
    begin
      attackType := 0;
      if (health < 1000) then
        attackType := 1;
      if (health < 200) then
        attackType := 2;
      attackTime := 60 * 2;
    end;
    exit;
  end;

  if (attackTime > 0) then
  begin
    dec(attackTime);
    fdir := attackTime * 0.25 * (attackTime mod 2 * 2 - 1);
    fspeed := (0.7) + attackType * 0.2;
    level.add(TSpark.create(self, cos(fdir) * fspeed, sin(fdir) * fspeed));
    exit;
  end;

  if (level.player <> nil) and (randomWalkTime = 0) then
  begin
    xd := level.player.x - x;
    yd := level.player.y - y;
    if (xd * xd + yd * yd < 32 * 32) then
    begin
      xa := 0;
      ya := 0;
      if (xd < 0) then
        xa := +1;
      if (xd > 0) then
        xa := -1;
      if (yd < 0) then
        ya := +1;
      if (yd > 0) then
        ya := -1;
    end
    else if (xd * xd + yd * yd > 80 * 80) then
    begin
      xa := 0;
      ya := 0;
      if (xd < 0) then
        xa := -1;
      if (xd > 0) then
        xa := +1;
      if (yd < 0) then
        ya := -1;
      if (yd > 0) then
        ya := +1;
    end;
  end;

  if (tickTime mod 4) = 0 then
    speed := 0
  else
    speed := 1;
  if (not move(xa * speed, ya * speed)) or (random(100) = 0) then
  begin
    randomWalkTime := 30;
    xa := (random(3) - 1);
    ya := (random(3) - 1);
  end;
  if (randomWalkTime > 0) then
  begin
    dec(randomWalkTime);
    if (level.player <> nil) and (randomWalkTime = 0) then
    begin
      xd := level.player.x - x;
      yd := level.player.y - y;
      if (random(4) = 0) and (xd * xd + yd * yd < 50 * 50) then
      begin
        if (attackDelay = 0) and (attackTime = 0) then
        begin
          attackDelay := 60 * 2;
        end;
      end;
    end;
  end;
end;

procedure TAirwizard.doHurt(damage, attackDir: integer);
begin
  inherited;
  if (attackDelay = 0) and (attackTime = 0) then
    attackDelay := 60 * 2;
end;

procedure TAirwizard.render(screen: TScreen);
var
  xt, yt: integer;
  flip1, flip2: integer;
  xo, yo: integer;
  col1, col2: cardinal;
begin
  xt := 8;
  yt := 14;

  flip1 := (walkDist shr 3) and 1;
  flip2 := (walkDist shr 3) and 1;

  if (dir = 1) then
    xt := xt + 2;

  if (dir > 1) then
  begin

    flip1 := 0;
    flip2 := ((walkDist shr 4) and 1);
    if (dir = 2) then
      flip1 := 1;

    xt := xt + (4 + ((walkDist shr 3) and 1) * 2);
  end;

  xo := x - 8;
  yo := y - 11;

  col1 := CalcColor(-1, 100, 500, 555);
  col2 := CalcColor(-1, 100, 500, 532);
  if (health < 200) then
  begin
    if (tickTime div 3) mod 2 = 0 then
    begin
      col1 := CalcColor(-1, 500, 100, 555);
      col2 := CalcColor(-1, 500, 100, 532);
    end;
  end
  else if (health < 1000) then
  begin
    if (tickTime div 5) mod 4 = 0 then
    begin
      col1 := CalcColor(-1, 500, 100, 555);
      col2 := CalcColor(-1, 500, 100, 532);
    end;
  end;
  if (hurtTime > 0) then
  begin
    col1 := CalcColor(-1, 555, 555, 555);
    col2 := CalcColor(-1, 555, 555, 555);
  end;

  screen.render(xo + 8 * flip1, yo + 0, xt + yt * 32, col1, flip1);
  screen.render(xo + 8 - 8 * flip1, yo + 0, xt + 1 + yt * 32, col1, flip1);
  screen.render(xo + 8 * flip2, yo + 8, xt + (yt + 1) * 32, col2, flip2);
  screen.render(xo + 8 - 8 * flip2, yo + 8, xt + 1 + (yt + 1) * 32,
    col2, flip2);
end;

procedure TAirwizard.touchedBy(entity: TEntity);
begin
  if (entity is TPlayer) then
    entity.hurt(self, 3, dir);
end;

procedure TAirwizard.die;
begin
  inherited;
  if (level.player <> nil) then
  begin
    level.player.score := level.player.score + 1000;
    level.player.GameWon();
  end;
  Sound.Play(sebossdeath);
end;

{ TPlayer }

constructor TPlayer.create(game: TGame; input: TInputHandler);
begin
  inherited create;

  self.game := game;
  self.input := input;
  x := 24;
  y := 24;
  maxstamina := 10;
  stamina := maxstamina;
  invulnerableTime := 0;
  inventory := TInventory.create;
  inventory.add(TFurnitureItem.create(TWorkbench.create));
  inventory.add(TPowerGloveItem.create);

{$IFDEF MSWINDOWS}
  // Cheat
  inventory.add(TResourceItem.create(Resources.res_flint, 100));
  inventory.add(TResourceItem.create(Resources.res_wood, 100));
  inventory.add(TResourceItem.create(Resources.res_stone, 100));
  inventory.add(TResourceItem.create(Resources.res_glass, 100));
  inventory.add(TResourceItem.create(Resources.res_coal, 100));
  inventory.add(TResourceItem.create(Resources.res_wheat, 100));
  inventory.add(TResourceItem.create(Resources.res_torch, 100));
{$ENDIF}
end;

destructor TPlayer.Destroy;
begin
  FreeAndNil(inventory);
  inherited;
end;

procedure TPlayer.Tick();
var
  onTile: TTile;
  xa, ya: integer;
begin
  inherited;

  if (invulnerableTime > 0) then
    dec(invulnerableTime);
  onTile := level.getTile(x shr 4, y shr 4);
  if (onTile = Resources.stairsDown) or (onTile = Resources.stairsUp) then
  begin
    if (onStairDelay = 0) then
    begin
      if onTile = Resources.stairsUp then
        changeLevel(1)
      else
        changeLevel(-1);
      onStairDelay := 10;
      exit;
    end;
    onStairDelay := 10;
  end
  else
  begin
    if (onStairDelay > 0) then
      dec(onStairDelay);
  end;

  if (stamina <= 0) and (staminaRechargeDelay = 0) and (staminaRecharge = 0)
  then
  begin
    staminaRechargeDelay := 40;
  end;

  if (staminaRechargeDelay > 0) then
    dec(staminaRechargeDelay);

  if (staminaRechargeDelay = 0) then
  begin
    inc(staminaRecharge);
    if isSwimming then
      staminaRecharge := 0;

    while (staminaRecharge > 10) do
    begin
      dec(staminaRecharge, 10);
      if (stamina < maxstamina) then
        inc(stamina);
    end;
  end;

  xa := 0;
  ya := 0;
  if (input.up.Down) then
    dec(ya);
  if (input.Down.Down) then
    inc(ya);
  if (input.left.Down) then
    dec(xa);
  if (input.right.Down) then
    inc(xa);

  if (isSwimming) and (tickTime mod 60 = 0) then
  begin
    if (stamina > 0) then
      dec(stamina)
    else
      hurt(self, 1, dir xor 1);
  end;

  if (staminaRechargeDelay mod 2 = 0) then
    move(xa, ya);

  if (input.attack.Clicked) then
  begin
    if (stamina = 0) then
    begin

    end
    else
    begin
      dec(stamina);
      staminaRecharge := 0;
      attack();
    end;
  end;

  if (attackTime > 0) then
    dec(attackTime);

  if (input.menu.Clicked) then
  begin
    if (not myuse) then
      game.setMenu(TInventoryMenu.create(self));
  end;
end;

function TPlayer.myuse(): Boolean;
var
  xt, yt, r, yo: integer;
begin
  yo := -2;
  Result := true;
  if (dir = 0) and (myuse(x - 8, y + 4 + yo, x + 8, y + 12 + yo)) then
    exit;
  if (dir = 1) and (myuse(x - 8, y - 12 + yo, x + 8, y - 4 + yo)) then
    exit;
  if (dir = 3) and (myuse(x + 4, y - 8 + yo, x + 12, y + 8 + yo)) then
    exit;
  if (dir = 2) and (myuse(x - 12, y - 8 + yo, x - 4, y + 8 + yo)) then
    exit;

  xt := x shr 4;
  yt := (y + yo) shr 4;
  r := 12;
  if (attackDir = 0) then
    yt := (y + r + yo) shr 4;
  if (attackDir = 1) then
    yt := (y - r + yo) shr 4;
  if (attackDir = 2) then
    xt := (x - r) shr 4;
  if (attackDir = 3) then
    xt := (x + r) shr 4;

  if (xt >= 0) and (yt >= 0) and (xt < level.w) and (yt < level.h) then
    if (level.getTile(xt, yt).use(level, xt, yt, self, attackDir)) then
      exit;

  Result := false;
end;

procedure TPlayer.attack();
var
  done: Boolean;
  yo, range: integer;
  r, xt, yt: integer;
begin
  inc(walkDist, 8);
  attackDir := dir;
  attackItem := activeItem;
  done := false;

  if (activeItem <> nil) then
  begin
    attackTime := 10;
    yo := -2;
    range := 12;
    if (dir = 0) and (myinteract(x - 8, y + 4 + yo, x + 8, y + range + yo)) then
      done := true;
    if (dir = 1) and (myinteract(x - 8, y - range + yo, x + 8, y - 4 + yo)) then
      done := true;
    if (dir = 3) and (myinteract(x + 4, y - 8 + yo, x + range, y + 8 + yo)) then
      done := true;
    if (dir = 2) and (myinteract(x - range, y - 8 + yo, x - 4, y + 8 + yo)) then
      done := true;
    if (done) then
      exit;

    xt := x shr 4;
    yt := (y + yo) shr 4;
    r := 12;
    if (attackDir = 0) then
      yt := (y + r + yo) shr 4;
    if (attackDir = 1) then
      yt := (y - r + yo) shr 4;
    if (attackDir = 2) then
      xt := (x - r) shr 4;
    if (attackDir = 3) then
      xt := (x + r) shr 4;

    if (xt >= 0) and (yt >= 0) and (xt < level.w) and (yt < level.h) then
    begin
      if (activeItem.interactOn(level.getTile(xt, yt), level, xt, yt, self,
        attackDir)) then
      begin
        done := true;
      end
      else
      begin
        if (level.getTile(xt, yt).interact(level, xt, yt, self, activeItem,
          attackDir)) then
        begin
          done := true;
        end;
      end;
      if (activeItem.isDepleted()) then
        activeItem := nil;
    end;
  end;

  if (done) then
    exit;

  if (activeItem = nil) or (activeItem.canAttack) then
  begin
    attackTime := 5;
    yo := -2;
    range := 20;

    if (dir = 0) then
      hurt(x - 8, y + 4 + yo, x + 8, y + range + yo);
    if (dir = 1) then
      hurt(x - 8, y - range + yo, x + 8, y - 4 + yo);
    if (dir = 3) then
      hurt(x + 4, y - 8 + yo, x + range, y + 8 + yo);
    if (dir = 2) then
      hurt(x - range, y - 8 + yo, x - 4, y + 8 + yo);

    xt := x shr 4;
    yt := (y + yo) shr 4;
    r := 12;
    if (attackDir = 0) then
      yt := (y + r + yo) shr 4;
    if (attackDir = 1) then
      yt := (y - r + yo) shr 4;
    if (attackDir = 2) then
      xt := (x - r) shr 4;
    if (attackDir = 3) then
      xt := (x + r) shr 4;

    if (xt >= 0) and (yt >= 0) and (xt < level.w) and (yt < level.h) then
      level.getTile(xt, yt).hurt(level, xt, yt, self, random(3) + 1, attackDir);
  end;
end;

function TPlayer.myuse(x0, y0, x1, y1: integer): Boolean;
var
  entities: TEntityList;
  i: integer;
  e: TEntity;
begin
  Result := false;
  entities := level.getEntities(x0, y0, x1, y1);
  for i := 0 to entities.count - 1 do
  begin
    e := entities[i];
    if (e <> self) and (e.use(self, attackDir)) then
    begin
      Result := true;
      break;
    end;
  end;
  FreeAndNil(entities);
end;

function TPlayer.myinteract(x0, y0, x1, y1: integer): Boolean;
var
  entities: TEntityList;
  i: integer;
  e: TEntity;

begin
  Result := false;
  entities := level.getEntities(x0, y0, x1, y1);
  for i := 0 to entities.count - 1 do
  begin
    e := entities[i];
    if (e <> self) and (e.interact(self, activeItem, attackDir)) then
    begin
      Result := true;
      break;
    end;
  end;
  FreeAndNil(entities);
end;

procedure TPlayer.hurt(x0, y0, x1, y1: integer);
var
  entities: TEntityList;
  i: integer;
  e: TEntity;

begin
  entities := level.getEntities(x0, y0, x1, y1);
  for i := 0 to entities.count - 1 do
  begin
    e := entities[i];
    if (e <> self) then
      e.hurt(self, getAttackDamage(e), attackDir);
  end;
  FreeAndNil(entities);
end;

function TPlayer.getAttackDamage(e: TEntity): integer;
var
  dmg: integer;
begin
  dmg := random(3) + 1;
  if (attackItem <> nil) then
    dmg := dmg + attackItem.getAttackDamageBonus(e);
  Result := dmg;
end;

procedure TPlayer.render(screen: TScreen);
var
  xo, yo, xt, yt: integer;
  flip1, flip2: integer;
  Furniture: TFurniture;
  col, waterColor: Cardinal;
begin
  xt := 0;
  yt := 14;

  flip1 := (walkDist shr 3) and 1;
  flip2 := (walkDist shr 3) and 1;

  if (dir = 1) then
    inc(xt, 2);

  if (dir > 1) then
  begin
    flip1 := 0;
    flip2 := ((walkDist shr 4) and 1);
    if (dir = 2) then
      flip1 := 1;
    xt := xt + (4 + ((walkDist shr 3) and 1) * 2);
  end;

  xo := x - 8;
  yo := y - 11;
  if (isSwimming) then
  begin
    inc(yo, 4);
    waterColor := CalcColor(-1, -1, 115, 335);
    if (tickTime div 8) mod 2 = 0 then
      waterColor := CalcColor(-1, 335, 5, 115);

    screen.render(xo + 0, yo + 3, 5 + 13 * 32, waterColor, 0);
    screen.render(xo + 8, yo + 3, 5 + 13 * 32, waterColor, 1);
  end;

  if (attackTime > 0) and (attackDir = 1) then
  begin
    screen.render(xo + 0, yo - 4, 6 + 13 * 32, CalcColor(-1, 555, 555, 555), 0);
    screen.render(xo + 8, yo - 4, 6 + 13 * 32, CalcColor(-1, 555, 555, 555), 1);
    if (attackItem <> nil) then
      attackItem.renderIcon(screen, xo + 4, yo - 4);
  end;

  col := CalcColor(-1, 100, 220, 532);
  if (hurtTime > 0) then
    col := CalcColor(-1, 555, 555, 555);

  if (activeItem is TFurnitureItem) then
    yt := yt + 2;

  screen.render(xo + 8 * flip1, yo + 0, xt + yt * 32, col, flip1);
  screen.render(xo + 8 - 8 * flip1, yo + 0, xt + 1 + yt * 32, col, flip1);
  if (not isSwimming()) then
  begin
    screen.render(xo + 8 * flip2, yo + 8, xt + (yt + 1) * 32, col, flip2);
    screen.render(xo + 8 - 8 * flip2, yo + 8, xt + 1 + (yt + 1) * 32,
      col, flip2);
  end;

  if (attackTime > 0) and (attackDir = 2) then
  begin
    screen.render(xo - 4, yo, 7 + 13 * 32, CalcColor(-1, 555, 555, 555), 1);
    screen.render(xo - 4, yo + 8, 7 + 13 * 32, CalcColor(-1, 555, 555, 555), 3);
    if (attackItem <> nil) then
      attackItem.renderIcon(screen, xo - 4, yo + 4);
  end;

  if (attackTime > 0) and (attackDir = 3) then
  begin
    screen.render(xo + 8 + 4, yo, 7 + 13 * 32, CalcColor(-1, 555, 555, 555), 0);
    screen.render(xo + 8 + 4, yo + 8, 7 + 13 * 32,
      CalcColor(-1, 555, 555, 555), 2);
    if (attackItem <> nil) then
      attackItem.renderIcon(screen, xo + 8 + 4, yo + 4);
  end;

  if (attackTime > 0) and (attackDir = 0) then
  begin
    screen.render(xo + 0, yo + 8 + 4, 6 + 13 * 32,
      CalcColor(-1, 555, 555, 555), 2);
    screen.render(xo + 8, yo + 8 + 4, 6 + 13 * 32,
      CalcColor(-1, 555, 555, 555), 3);
    if (attackItem <> nil) then
      attackItem.renderIcon(screen, xo + 4, yo + 8 + 4);
  end;

  if (activeItem is TFurnitureItem) then
  begin
    Furniture := TFurnitureItem(activeItem).Furniture;
    Furniture.x := x;
    Furniture.y := yo;
    Furniture.render(screen);
  end;
end;

procedure TPlayer.touchItem(ItemEntity: TItemEntity);
begin
  ItemEntity.take(self);
  inventory.add(ItemEntity.item);
end;

function TPlayer.canSwim(): Boolean;
begin
  Result := true;
end;

function TPlayer.findStartPos(level: TLevel): Boolean;
var
  count, x, y: integer;
begin
  Result := true;

  count := 0;
  while (true) do
  begin
    x := random(level.w);
    y := random(level.h);
    inc(count);
    if (level.getTile(x, y) = Resources.grass) or (count > 1000) then
    begin
      level.setTile(x, y, Resources.grass, 0);
      self.x := x * 16 + 8;
      self.y := y * 16 + 8;
      exit;
    end;
  end;
end;

function TPlayer.payStamina(cost: integer): Boolean;
begin
  if (cost > stamina) then
    Result := false
  else
  begin
    stamina := stamina - cost;
    Result := true;
  end;
end;

function TPlayer.getLightRadius(): integer;
var
  rr, r: integer;
begin
  r := 2;
  if (activeItem <> nil) then
  begin
    if (activeItem is TFurnitureItem) then
    begin
      rr := TFurnitureItem(activeItem).Furniture.getLightRadius();
      if (rr > r) then
        r := rr;
    end;
  end;
  Result := r;
end;

procedure TPlayer.die();
begin
  inherited;
  Sound.Play(seplayerDeath);
end;

procedure TPlayer.touchedBy(entity: TEntity);
begin
  if (not(entity is TPlayer)) then
    entity.touchedBy(self);
end;

procedure TPlayer.doHurt(damage, attackDir: integer);
begin
  if (hurtTime > 0) or (invulnerableTime > 0) then
    exit;

  Sound.Play(seplayerHurt);
  level.add(TTextParticle.create(inttostr(damage), x, y, CalcColor(-1, 504,
    504, 504)));
  dec(health, damage);
  if (attackDir = 0) then
    yKnockback := +6;
  if (attackDir = 1) then
    yKnockback := -6;
  if (attackDir = 2) then
    xKnockback := -6;
  if (attackDir = 3) then
    xKnockback := +6;
  hurtTime := 10;
  invulnerableTime := 30;
end;

procedure TPlayer.changeLevel(dir: integer);
begin
  game.scheduleLevelChange(dir);
end;

procedure TPlayer.GameWon();
begin
  level.player.invulnerableTime := 60 * 5;
  game.won();
end;

// -----------------------------------------------------------------------------

{ TFurniture }

constructor TFurniture.create;
begin
  inherited create;
  pushTime := 0;
  pushDir := -1;
  name := '';
  xr := 3;
  yr := 3;
  InitSprite;
end;

procedure TFurniture.InitSprite;
begin
end;

procedure TFurniture.Tick();
begin
  if (shouldTake <> nil) then
  begin
    if (shouldTake.activeItem is TPowerGloveItem) then
    begin
      remove();
      shouldTake.inventory.add(0, shouldTake.activeItem);
      shouldTake.activeItem := TFurnitureItem.create(self);
    end;
    shouldTake := nil;
  end;
  if (pushDir = 0) then
    move(0, +1);
  if (pushDir = 1) then
    move(0, -1);
  if (pushDir = 2) then
    move(-1, 0);
  if (pushDir = 3) then
    move(+1, 0);
  pushDir := -1;
  if (pushTime > 0) then
    dec(pushTime);
end;

procedure TFurniture.render(screen: TScreen);
begin
  screen.render(x - 8, y - 8 - 4, sprite * 2 + 8 * 32, col, 0);
  screen.render(x - 0, y - 8 - 4, sprite * 2 + 8 * 32 + 1, col, 0);
  screen.render(x - 8, y - 0 - 4, sprite * 2 + 8 * 32 + 32, col, 0);
  screen.render(x - 0, y - 0 - 4, sprite * 2 + 8 * 32 + 33, col, 0);
end;

function TFurniture.blocks(e: TEntity): Boolean;
begin
  Result := true;
end;

procedure TFurniture.touchedBy(entity: TEntity);
begin
  if (entity is TPlayer) and (pushTime = 0) then
  begin
    pushDir := TPlayer(entity).dir;
    pushTime := 10;
  end;
end;

procedure TFurniture.take(player: TPlayer);
begin
  shouldTake := player;
end;

{ TLantern }

procedure TLantern.InitSprite;
begin
  name := 'Lantern';
  col := CalcColor(-1, 000, 111, 555);
  sprite := 5;
  xr := 3;
  yr := 2;
end;

function TLantern.getLightRadius(): integer;
begin
  Result := 8;
end;

{ TWorkbench }

procedure TWorkbench.InitSprite;
begin
  name := 'Workbench';
  col := CalcColor(-1, 100, 321, 431);
  sprite := 4;
  xr := 3;
  yr := 2;
end;

function TWorkbench.use(player: TPlayer; attackDir: integer): Boolean;
begin
  player.game.setMenu(TCraftingMenu.create(Crafting.workbenchRecipes, player));
  Result := true;
end;

{ TFurnace }

procedure TFurnace.InitSprite;
begin
  name := 'Furnace';
  col := CalcColor(-1, 000, 222, 333);
  sprite := 3;
  xr := 3;
  yr := 2;
end;

function TFurnace.use(player: TPlayer; attackDir: integer): Boolean;
begin
  player.game.setMenu(TCraftingMenu.create(Crafting.furnaceRecipes, player));
  Result := true;
end;

{ TAnvil }

procedure TAnvil.InitSprite;
begin
  name := 'Anvil';
  col := CalcColor(-1, 000, 111, 222);
  sprite := 0;
  xr := 3;
  yr := 2;
end;

function TAnvil.use(player: TPlayer; attackDir: integer): Boolean;
begin
  player.game.setMenu(TCraftingMenu.create(Crafting.anvilRecipes, player));
  Result := true;
end;

{ TBrewery }
{
  procedure TBrewery.InitSprite;
  begin
  name := 'Brewery';
  col := CalcColor(-1, 000, 224, 335);
  sprite := 3;
  xr := 3;
  yr := 2;
  end;

  function TBrewery.use(player: TPlayer; attackDir: integer): Boolean;
  begin
  player.game.setMenu(TCraftingMenu.create(Crafting.breweryRecipes, player));
  Result := true;
  end;
}
{ TOven }

procedure TOven.InitSprite;
begin
  name := 'Oven';
  col := CalcColor(-1, 000, 332, 442);
  sprite := 2;
  xr := 3;
  yr := 2;
end;

function TOven.use(player: TPlayer; attackDir: integer): Boolean;
begin
  player.game.setMenu(TCraftingMenu.create(Crafting.ovenRecipes, player));
  Result := true;
end;

{ TFire }

constructor TFire.create;
begin
  create(nil, 0, 0, 1, 100);
end;

constructor TFire.create(owner: TLivingEntity; x, y: integer);
begin
  create(owner, x, y, 1, 100);
end;

constructor TFire.create(owner: TLivingEntity;
x, y, burnPower, burnCycle: integer);
begin
  inherited create;

  self.owner := owner;
  self.x := x;
  self.y := y;
  self.burnPower := burnPower;
  self.burnCycle := burnCycle;
end;

procedure TFire.Tick;
begin
  inc(time);

  // eat some fuel
  if (time mod burnCycle = 0) then
    BurnFuel();

  // spread all around
  self.TrySpreading();

  // change the graphics
  if (time mod 5 = 0) then
  begin
    self.renderFlip := BIT_MIRROR_X * random(2);
    self.renderImg := random(3);
  end;

  // harm entities all around
  self.harmNearbyEntities();
end;

function TFire.isBlockableBy(mob: TMob): Boolean;
begin
  Result := false;
end;

procedure TFire.render(screen: TScreen);
var
  xt, yt: integer;
  flip, fx: integer;
  col: cardinal;
begin
  xt := 30;
  yt := renderImg * 2;
  flip := renderFlip;
  if flip = 0 then
    fx := 1
  else
    fx := -1;

  col := CalcColor(-1, 530, 541, 553);
  screen.render(x - 4 * fx, y - 8, xt + yt * 32, col, flip);
  screen.render(x + 4 * fx, y - 8, xt + 1 + yt * 32, col, flip);
  screen.render(x - 4 * fx, y, xt + (yt + 1) * 32, col, flip);
  screen.render(x + 4 * fx, y, xt + 1 + (yt + 1) * 32, col, flip);
end;

function TFire.getLightRadius(): integer;
begin
  Result := burnPower * 5;
end;

procedure TFire.BurnFuel();
var
  xt, yt: integer;
  onTile: TTile;
begin
  xt := x shr 4;
  yt := y shr 4;
  onTile := level.getTile(xt, yt);
  if (onTile.isFlammable(level, xt, yt)) then
  begin
    // burn!
    onTile.burnFireFuel(level, xt, yt, burnPower, self);
  end
  else
    // out of fuel :(
    self.remove();
end;

procedure TFire.TrySpreading();
var
  fx, fy: integer;
begin
  if (random(burnCycle * 4 div burnPower) = 0) then
  begin
    fx := x + ((random(8) + 8) * (random(2) * 2 - 1));
    fy := y + ((random(8) + 8) * (random(2) * 2 - 1));
    if (level.getTile(fx shr 4, fy shr 4).isFlammable(level, fx shr 4, fy shr 4))
    then
      level.add(TFire.create(self.owner, fx, fy));
  end;
end;

procedure TFire.harmNearbyEntities();
var
  toHit: TEntityList;
  e: TEntity;
  i: integer;
begin
  toHit := level.getEntities(x - 1, y - 1, x + 1, y + 1);
  try
    for i := 0 to toHit.count - 1 do
    begin
      e := toHit[i];
      if (e is TLivingEntity) then
        e.hurt(owner, burnPower, (TLivingEntity(e)).dir xor 1);
    end;
  finally
    toHit.Free;
  end;
end;

{ TTorch }

constructor TTorch.create(owner: TLivingEntity; x, y: integer;
burnCapacity: integer = 10; burnPower: integer = 1; burnCycle: integer = 1000);
begin
  inherited create(owner, x, y, burnPower, burnCycle);
  self.burnPower := burnPower;
  self.burnCapacity := burnCapacity;
  self.burnCycle := burnCycle;
end;

procedure TTorch.render(screen: TScreen);
var
  xt, yt: integer;
  col: cardinal;
begin
  xt := 12;
  yt := renderImg * 2 + 8;
  col := CalcColor(-1, 410, 540, 553);
  screen.render(x - 8, y - 10, xt + yt * 32, col, 0);
  screen.render(x, y - 10, xt + 1 + yt * 32, col, 0);
  screen.render(x - 8, y - 2, xt + (yt + 1) * 32, col, 0);
  screen.render(x, y - 2, xt + 1 + (yt + 1) * 32, col, 0);
end;

procedure TTorch.hurt(mob: TLivingEntity; const dmg, attackDir: integer);
begin
  remove;
end;

function TTorch.use(player: TPlayer; atackdir: integer): Boolean;
begin
  remove();
  player.inventory.add(TResourceItem.create(Resources.res_torch));
  Result := true;
end;

function TTorch.getLightRadius: integer;
begin
  Result := burnPower * 8;
end;

procedure TTorch.TrySpreading;
begin
  if (random(10) = 0) then
    inherited TrySpreading();
end;

procedure TTorch.harmNearbyEntities;
var
  toHit: TEntityList;
  i: integer;
  e: TEntity;
begin
  if (random(10) = 0) then
  begin
    toHit := level.getEntities(x, y, x, y);
    for i := 0 to toHit.count - 1 do
    begin
      e := toHit[i];
      if (e is TLivingEntity) and
        ((x shr 4 = e.x shr 4) and (y shr 4 = e.y shr 4)) then
      begin
        e.hurt(owner, burnPower, TLivingEntity(e).dir xor 1);
      end;
    end;
    FreeAndNil(toHit);
  end;
end;

procedure TTorch.BurnFuel;
begin
  burnCapacity := burnCapacity - burnPower;
  if (burnCapacity <= 0) then
    remove();
end;

{ TChest }

procedure TChest.InitSprite;
begin
  name := 'Chest';
  inventory := TInventory.create;
  col := CalcColor(-1, 110, 331, 552);
  sprite := 1;
end;

destructor TChest.Destroy;
begin
  FreeAndNil(inventory);
  inherited;
end;

function TChest.use(player: TPlayer; attackDir: integer): Boolean;
begin
  player.game.setMenu(TContainerMenu.create(player, 'Chest', inventory));
  Result := true;
end;

{ TParticle }

procedure TParticle.Tick;
begin
end;

{ TSmashParticle }

constructor TSmashParticle.create(x, y: integer);
begin
  inherited create;
  time := 0;
  self.x := x;
  self.y := y;
  Sound.Play(seMonsterHurt);
end;

procedure TSmashParticle.Tick();
begin
  inc(time);
  if (time > 10) then
    remove();
end;

procedure TSmashParticle.render(screen: TScreen);
var
  col: Cardinal;
begin
  col := CalcColor(-1, 555, 555, 555);
  screen.render(x - 8, y - 8, 5 + 12 * 32, col, 2);
  screen.render(x - 0, y - 8, 5 + 12 * 32, col, 3);
  screen.render(x - 8, y - 0, 5 + 12 * 32, col, 0);
  screen.render(x - 0, y - 0, 5 + 12 * 32, col, 1);
end;

{ TTextParticle }

constructor TTextParticle.create(msg: string; x, y: integer; col: Cardinal);
begin
  inherited create;
  time := 0;
  self.msg := msg;
  self.x := x;
  self.y := y;
  self.col := col;
  xx := x;
  yy := y;
  zz := 2;
  xa := RandomGaussian() * 0.3;
  ya := RandomGaussian() * 0.2;
  za := RandomFloat() * 0.7 + 2;
end;

procedure TTextParticle.Tick();
begin
  inc(time);
  if (time > 60) then
    remove();
  xx := xx + xa;
  yy := yy + ya;
  zz := zz + za;
  if (zz < 0) then
  begin
    zz := 0;
    za := za * -0.5;
    xa := xa * 0.6;
    ya := ya * 0.6;
  end;
  za := za - 0.15;
  x := Trunc(xx);
  y := Trunc(yy);
end;

procedure TTextParticle.render(screen: TScreen);
begin
  Font.draw(msg, screen, x - length(msg) * 4 + 1, y - Trunc(zz) + 1,
    CalcColor(-1, 0, 0, 0));
  Font.draw(msg, screen, x - length(msg) * 4, y - Trunc(zz), col);
end;

{ TSpark }

constructor TSpark.create(owner: TAirwizard; xa, ya: single);
begin
  inherited create;
  self.owner := owner;
  xx := owner.x;
  self.x := owner.x;
  yy := owner.y;
  self.y := owner.y;

  xr := 0;
  yr := 0;

  self.xa := xa;
  self.ya := ya;

  lifeTime := 60 * 10 + random(30);
end;

procedure TSpark.Tick();
var
  toHit: TEntityList;
  i: integer;
  e: TEntity;
begin
  inc(time);
  if (time >= lifeTime) then
  begin
    remove();
    exit;
  end;

  xx := xx + xa;
  yy := yy + ya;
  x := Trunc(xx);
  y := Trunc(yy);
  toHit := level.getEntities(x, y, x, y);
  for i := 0 to toHit.count - 1 do
  begin
    e := toHit[i];
    if (e is TMob) and (not(e is TAirwizard)) then
    begin
      e.hurt(owner, 1, TMob(e).dir xor 1);
    end;
  end;
  FreeAndNil(toHit);
end;

function TSpark.isBlockableBy(mob: TMob): Boolean;
begin
  Result := false;
end;

procedure TSpark.render(screen: TScreen);
var
  xt, yt: integer;
begin
  if (time >= lifeTime - 6 * 20) then
  begin
    if (time div 6) mod 2 = 0 then
      exit;
  end;

  xt := 8;
  yt := 13;

  screen.render(x - 4, y - 4 - 2, xt + yt * 32, CalcColor(-1, 555, 555, 555),
    random(4));
  screen.render(x - 4, y - 4 + 2, xt + yt * 32, CalcColor(-1, 000, 000, 000),
    random(4));
end;

{ TInventory }

constructor TInventory.create;
begin
  Items := TItemList.create;
end;

destructor TInventory.Destroy;
var
  i: integer;
  Obj: TObject;
begin
  for i := 0 to Items.count - 1 do
  begin
    Obj := Items[i];
    FreeAndNil(Obj);
  end;

  Items.clear;
  FreeAndNil(Items);
  inherited;
end;

procedure TInventory.add(item: TListItem);
begin
  add(Items.count, item);
end;

procedure TInventory.add(slot: integer; item: TListItem);
var
  has, toTake: TResourceItem;
begin
  if (item is TResourceItem) then
  begin
    toTake := TResourceItem(item);
    has := findResource(toTake.Resource);
    if (has = nil) then
      Items.insert(slot, toTake)
    else
    begin
      has.count := has.count + toTake.count;
      // FreeAndNil(item); // TODO
    end;
  end
  else
    Items.insert(slot, item);
end;

function TInventory.findResource(Resource: TResource): TResourceItem;
var
  i: integer;
  has: TResourceItem;
  item: TListItem;
begin
  Result := nil;
  for i := 0 to Items.count - 1 do
  begin
    item := Items[i];
    try
      if item is TResourceItem then
      begin
        has := TResourceItem(item);
        if (has.Resource = Resource) then
        begin
          Result := has;
          exit;
        end;
      end;
    except
    end;
  end;
end;

function TInventory.hasResources(r: TResource; count: integer): Boolean;
var
  ri: TResourceItem;
begin
  ri := findResource(r);
  if assigned(ri) then
    Result := ri.count >= count
  else
    Result := false;
end;

function TInventory.removeResource(r: TResource; count: integer): Boolean;
var
  ri: TResourceItem;
begin
  ri := findResource(r);
  if (ri = nil) or (ri.count < count) then
  begin
    Result := false;
    exit;
  end;
  ri.count := ri.count - count;

  if (ri.count <= 0) then
  begin
    Items.remove(ri);
    FreeAndNil(ri); // TODO
  end;
  Result := true;
end;

function TInventory.count(item: TItem): integer;
var
  ri: TResourceItem;
  count, i: integer;
begin
  Result := 0;
  if item is TResourceItem then
  begin
    ri := findResource(TResourceItem(item).Resource);
    if assigned(ri) then
      Result := ri.count;
  end
  else
  begin
    count := 0;
    for i := 0 to Items.count - 1 do
    begin
      if (TItem(Items[i]).matches(item)) then
        inc(count);
    end;
    Result := count;
  end;
end;

// Recipes ---------------------------------------------------------------------

constructor TRecipe.create(resultTemplate: TItem);
begin
  self.resultTemplate := resultTemplate;
  costs := TResourceList.create;
  canCraft := false;
end;

destructor TRecipe.Destroy;
var
  i: integer;
  Obj: TObject;
begin
  for i := 0 to costs.count - 1 do
  begin
    Obj := costs[i];
    FreeAndNil(Obj);
  end;

  FreeAndNil(resultTemplate); // TODO
  FreeAndNil(costs);
  inherited;
end;

function TRecipe.addCost(Resource: TResource; count: integer): TRecipe;
begin
  costs.add(TResourceItem.create(Resource, count));
  Result := self;
end;

procedure TRecipe.checkCanCraft(player: TPlayer);
var
  i: integer;
  item: TItem;
  ri: TResourceItem;
begin
  for i := 0 to costs.count - 1 do
  begin
    item := costs[i];
    if (item is TResourceItem) then
    begin
      ri := TResourceItem(item);
      if (not player.inventory.hasResources(ri.Resource, ri.count)) then
      begin
        canCraft := false;
        exit;
      end;
    end;
  end;
  canCraft := true;
end;

procedure TRecipe.renderInventory(const screen: TScreen; x, y: integer);
var
  textColor: Cardinal;
begin
  screen.render(x, y, resultTemplate.getSprite(), resultTemplate.getColor(), 0);
  if canCraft then
    textColor := CalcColor(-1, 555, 555, 555)
  else
    textColor := CalcColor(-1, 222, 222, 222);
  Font.draw(resultTemplate.getName(), screen, x + 8, y, textColor);
end;

procedure TRecipe.craft(player: TPlayer);
begin
end;

procedure TRecipe.deductCost(player: TPlayer);
var
  i: integer;
  item: TItem;
  ri: TResourceItem;
begin
  for i := 0 to costs.count - 1 do
  begin
    item := costs[i];
    if (item is TResourceItem) then
    begin
      ri := TResourceItem(item);
      player.inventory.removeResource(ri.Resource, ri.count);
    end;
  end;
end;

{ TFurnitureRecipe }

constructor TFurnitureRecipe.create(const Furniture: TFurnitureClass);
begin
  item := TFurnitureItem.create(Furniture.create);
  inherited create(item);
end;

destructor TFurnitureRecipe.Destroy;
begin
  inherited;
end;

procedure TFurnitureRecipe.craft(player: TPlayer);
begin
  player.inventory.add(0, item);
end;

{ TResourceRecipe }

constructor TResourceRecipe.create(Resource: TResource; count: integer = 1);
begin
  inherited create(TResourceItem.create(Resource, 1));
  self.Resource := Resource;
  self.count := count;
end;

procedure TResourceRecipe.craft(player: TPlayer);
begin
  player.inventory.add(0, TResourceItem.create(Resource, count));
end;

{ TToolRecipe }

constructor TToolRecipe.create(typ: TToolType; level: integer);
begin
  inherited create(TToolItem.create(typ, level));
  self.typ := typ;
  self.level := level;
end;

procedure TToolRecipe.craft(player: TPlayer);
begin
  player.inventory.add(0, TToolItem.create(typ, level));
end;

constructor TCrafting.create;
begin
  anvilRecipes := TRecipeList.create;
  ovenRecipes := TRecipeList.create;
  furnaceRecipes := TRecipeList.create;
  workbenchRecipes := TRecipeList.create;
  // breweryRecipes := TRecipeList.create;

  workbenchRecipes.add(TFurnitureRecipe.create(TLantern)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_slime, 10)
    .addCost(Resources.res_glass, 4));

  workbenchRecipes.add(TFurnitureRecipe.create(TOven)
    .addCost(Resources.res_stone, 15));
  workbenchRecipes.add(TFurnitureRecipe.create(TFurnace)
    .addCost(Resources.res_stone, 20));
  workbenchRecipes.add(TFurnitureRecipe.create(TWorkbench)
    .addCost(Resources.res_wood, 20));
  workbenchRecipes.add(TFurnitureRecipe.create(TChest)
    .addCost(Resources.res_wood, 20));
  workbenchRecipes.add(TFurnitureRecipe.create(TAnvil)
    .addCost(Resources.res_ironIngot, 5));
  { workbenchRecipes.add(TFurnitureRecipe.create(TBrewery)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_glass, 2)
    .addCost(Resources.res_bottle, 1));
  }
  workbenchRecipes.add(TToolRecipe.create(Tooltypes.sword, 0)
    .addCost(Resources.res_wood, 5));
  workbenchRecipes.add(TToolRecipe.create(Tooltypes.axe, 0)
    .addCost(Resources.res_wood, 5));
  workbenchRecipes.add(TToolRecipe.create(Tooltypes.hoe, 0)
    .addCost(Resources.res_wood, 5));
  workbenchRecipes.add(TToolRecipe.create(Tooltypes.pickaxe, 0)
    .addCost(Resources.res_wood, 5));
  workbenchRecipes.add(TToolRecipe.create(Tooltypes.shovel, 0)
    .addCost(Resources.res_wood, 5));
  workbenchRecipes.add(TToolRecipe.create(Tooltypes.sword, 1)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_stone, 5));
  workbenchRecipes.add(TToolRecipe.create(Tooltypes.axe, 1)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_stone, 5));
  workbenchRecipes.add(TToolRecipe.create(Tooltypes.hoe, 1)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_stone, 5));
  workbenchRecipes.add(TToolRecipe.create(Tooltypes.pickaxe, 1)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_stone, 5));
  workbenchRecipes.add(TToolRecipe.create(Tooltypes.shovel, 1)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_stone, 5));
  workbenchRecipes.add(TResourceRecipe.create(Resources.res_plank, 4)
    .addCost(Resources.res_wood, 2));
  workbenchRecipes.add(TResourceRecipe.create(Resources.res_stoneTile, 4)
    .addCost(Resources.res_stone, 2));
  workbenchRecipes.add(TResourceRecipe.create(Resources.res_door, 1)
    .addCost(Resources.res_wood, 1).addCost(Resources.res_plank, 4));
  workbenchRecipes.add(TResourceRecipe.create(Resources.res_window, 1)
    .addCost(Resources.res_glass, 4).addCost(Resources.res_plank, 4));
  workbenchRecipes.add(TResourceRecipe.create(Resources.res_torch, 1)
    .addCost(Resources.res_wood, 4).addCost(Resources.res_slime, 1));

  anvilRecipes.add(TToolRecipe.create(Tooltypes.sword, 2)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_ironIngot, 5));
  anvilRecipes.add(TToolRecipe.create(Tooltypes.axe, 2)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_ironIngot, 5));
  anvilRecipes.add(TToolRecipe.create(Tooltypes.hoe, 2)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_ironIngot, 5));
  anvilRecipes.add(TToolRecipe.create(Tooltypes.pickaxe, 2)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_ironIngot, 5));
  anvilRecipes.add(TToolRecipe.create(Tooltypes.shovel, 2)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_ironIngot, 5));

  anvilRecipes.add(TToolRecipe.create(Tooltypes.sword, 3)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_goldIngot, 5));
  anvilRecipes.add(TToolRecipe.create(Tooltypes.axe, 3)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_goldIngot, 5));
  anvilRecipes.add(TToolRecipe.create(Tooltypes.hoe, 3)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_goldIngot, 5));
  anvilRecipes.add(TToolRecipe.create(Tooltypes.pickaxe, 3)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_goldIngot, 5));
  anvilRecipes.add(TToolRecipe.create(Tooltypes.shovel, 3)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_goldIngot, 5));

  anvilRecipes.add(TToolRecipe.create(Tooltypes.sword, 4)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_gem, 50));
  anvilRecipes.add(TToolRecipe.create(Tooltypes.axe, 4)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_gem, 50));
  anvilRecipes.add(TToolRecipe.create(Tooltypes.hoe, 4)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_gem, 50));
  anvilRecipes.add(TToolRecipe.create(Tooltypes.pickaxe, 4)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_gem, 50));
  anvilRecipes.add(TToolRecipe.create(Tooltypes.shovel, 4)
    .addCost(Resources.res_wood, 5).addCost(Resources.res_gem, 50));

  furnaceRecipes.add(TResourceRecipe.create(Resources.res_ironIngot)
    .addCost(Resources.res_ironOre, 4).addCost(Resources.res_coal, 1));
  furnaceRecipes.add(TResourceRecipe.create(Resources.res_goldIngot)
    .addCost(Resources.res_goldOre, 4).addCost(Resources.res_coal, 1));
  furnaceRecipes.add(TResourceRecipe.create(Resources.res_glass)
    .addCost(Resources.res_sand, 4).addCost(Resources.res_coal, 1));
  furnaceRecipes.add(TResourceRecipe.create(Resources.res_bottle)
    .addCost(Resources.res_glass, 1).addCost(Resources.res_coal, 1));

  ovenRecipes.add(TResourceRecipe.create(Resources.res_bread)
    .addCost(Resources.res_wheat, 4));

  { breweryRecipes.add(TResourceRecipe.create(Resources.res_ale)
    .addCost(Resources.res_wheat, 4).addCost(Resources.res_bottle, 1)
    .addCost(Resources.res_coal, 1));
  }
end;

destructor TCrafting.Destroy;
var
  i: integer;
  Obj: TObject;
begin
  for i := 0 to anvilRecipes.count - 1 do
  begin
    Obj := anvilRecipes[i];
    FreeAndNil(Obj);
  end;
  for i := 0 to ovenRecipes.count - 1 do
  begin
    Obj := ovenRecipes[i];
    FreeAndNil(Obj);
  end;

  for i := 0 to furnaceRecipes.count - 1 do
  begin
    Obj := furnaceRecipes[i];
    FreeAndNil(Obj);
  end;

  for i := 0 to workbenchRecipes.count - 1 do
  begin
    Obj := workbenchRecipes[i];
    FreeAndNil(Obj);
  end;

  { for i := 0 to breweryRecipes.count - 1 do
    begin
    Obj := breweryRecipes[i];
    FreeAndNil(Obj);
    end;
  }
  FreeAndNil(anvilRecipes);
  FreeAndNil(ovenRecipes);
  FreeAndNil(furnaceRecipes);
  FreeAndNil(workbenchRecipes);
  // FreeAndNil(breweryRecipes);

  inherited;
end;

// ------ Display and Game -----------------------------------------------------

constructor TScreen.create(const _w, _h: integer; _Sheet: TSpriteSheet);
begin
  sheet := _Sheet;
  w := _w;
  h := _h;

  Setlength(pixels, w * h);
end;

procedure TScreen.clear(const color: Cardinal);
var
  i: integer;
begin
  for i := 0 to high(pixels) do
    pixels[i] := color;
end;

procedure TScreen.render(xp, yp: integer; const tile: integer;
const colors, bits: Cardinal);
var
  mirrorX, mirrorY: Boolean;
  toffs, xTile, yTile: integer;
  col: Cardinal;
  x, xs, y, ys: integer;
begin
  xp := xp - xOffset;
  yp := yp - yOffset;
  mirrorX := (bits and BIT_MIRROR_X) > 0;
  mirrorY := (bits and BIT_MIRROR_Y) > 0;

  xTile := tile mod 32;
  yTile := tile div 32;
  toffs := xTile * 8 + yTile * 8 * sheet.Width;

  for y := 0 to 7 do
  begin
    ys := y;
    if (mirrorY) then
      ys := 7 - y;
    if (y + yp >= 0) and (y + yp < h) then
      for x := 0 to 7 do
        if (x + xp >= 0) and (x + xp < w) then
        begin
          xs := x;
          if (mirrorX) then
            xs := 7 - x;
          col := (colors shr (sheet.pixels[xs + ys * sheet.Width + toffs] *
            8)) and 255;
          if (col < 255) then
            pixels[(x + xp) + (y + yp) * w] := col;
        end;
  end;
end;

procedure TScreen.setOffset(const _xOffset, _yOffset: integer);
begin
  xOffset := _xOffset;
  yOffset := _yOffset;
end;

procedure TScreen.overlay(screen2: TScreen; const xa, ya: integer);
var
  x, y, i: integer;
begin
  i := 0;
  for y := 0 to h - 1 do
  begin
    for x := 0 to w - 1 do
    begin
      if (screen2.pixels[i] div 10 <= dither[((x + xa) and 3) + ((y + ya) and 3)
        * 4]) then
        pixels[i] := 0;
      inc(i);
    end;
  end;
end;

function TScreen.GetPixel(const x, y: integer): integer;
begin
  if (x < 0) or (y < 0) or (x >= w) or (y >= h) then
    Result := 0
  else
    Result := pixels[x + y * w];
end;

procedure TScreen.renderPoint(xp: integer; yp: integer; size: integer;
col: Cardinal);
var
  x, y: integer;
begin
  if (col < 255) then
  begin
    xp := xp - xOffset;
    yp := yp - yOffset;

    for y := 0 to size - 1 do
      if (y + yp >= 0) and (y + yp < h) then
        for x := 0 to size - 1 do
          if (x + xp >= 0) and (x + xp < w) then
            pixels[(x + xp) + (y + yp) * w] := col;
  end;
end;

procedure TScreen.copyRect(screen2: TScreen; const x2, y2, w2, h2: integer);
var
  x, y: integer;
begin
  for y := 0 to h2 - 1 do
    for x := 0 to w2 - 1 do
      screen2.pixels[(x + x2) + (y + y2) * screen2.w] := pixels[x + y * w];
end;

procedure TScreen.renderLight(x, y, r: integer);
var
  yy, yd, xd, xx: integer;
  x0, x1, y0, y1: integer;
  br: Byte;
  dist: integer;
begin
  x := x - xOffset;
  y := y - yOffset;
  x0 := x - r;
  x1 := x + r;
  y0 := y - r;
  y1 := y + r;

  if (x0 < 0) then
    x0 := 0;
  if (y0 < 0) then
    y0 := 0;
  if (x1 > w) then
    x1 := w;
  if (y1 > h) then
    y1 := h;

  for yy := y0 to y1 - 1 do
  begin
    yd := yy - y;
    yd := yd * yd;
    for xx := x0 to x1 - 1 do
    begin
      xd := xx - x;
      dist := xd * xd + yd;
      if (dist <= r * r) then
      begin
        br := 255 - dist * 255 div (r * r);
        if (pixels[xx + yy * w] < br) then
          pixels[xx + yy * w] := br;
      end;
    end;
  end;
end;

destructor TScreen.Destroy;
begin
  Setlength(pixels, 0);
  FreeAndNil(sheet);

  inherited;
end;

{ TSpriteSheet }

constructor TSpriteSheet.create(const w, h: integer;
const image: TGamePixelBuffer);
var
  i, x, y: integer;
begin
  Width := w;
  Height := h;
  i := 0;
  Setlength(pixels, Width * Height);
  for y := 0 to h - 1 do
    for x := 0 to w - 1 do
    begin
      pixels[i] := image[i];
      pixels[i] := (pixels[i] and $FF) div 64;
      inc(i);
    end;
end;

destructor TSpriteSheet.Destroy;
begin
  Setlength(pixels, 0);
  inherited;
end;

{ TSprite }

constructor TSprite.create(const x, y, img: integer; col: Cardinal;
bits: integer);
begin
  inherited create;
  self.x := x;
  self.y := y;
  self.img := img;
  self.col := col;
  self.bits := bits;
end;

{ TFont }

procedure TFont.draw(msg: string; const screen: TScreen; const x, y: integer;
const col: Cardinal);
const
  cChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ      0123456789.,!?'#39 +
    '"-+=/\%()<>:;     ';

var
  offs, ix, i: integer;
begin
  msg := uppercase(msg);

  if x = -1 then
    offs := (screen.w - length(msg) * 8) div 2
  else
    offs := x;

  for i := 0 to length(msg) - 1 do
  begin
    ix := pos(CharFromStr(msg, i), cChars) - 1;
    if (ix >= 0) then
      screen.render(offs + i * 8, y, ix + 30 * 32, col, 0);
  end;
end;

procedure TFont.renderFrame(const screen: TScreen; const title: string;
const x0, y0, x1, y1: integer);
var
  x, y: integer;
begin
  for y := y0 to y1 do
  begin
    for x := x0 to x1 do
    begin
      if (x = x0) and (y = y0) then
        screen.render(x * 8, y * 8, 0 + 13 * 32, CalcColor(-1, 1, 5, 445), 0)
      else if (x = x1) and (y = y0) then
        screen.render(x * 8, y * 8, 0 + 13 * 32, CalcColor(-1, 1, 5, 445), 1)
      else if (x = x0) and (y = y1) then
        screen.render(x * 8, y * 8, 0 + 13 * 32, CalcColor(-1, 1, 5, 445), 2)
      else if (x = x1) and (y = y1) then
        screen.render(x * 8, y * 8, 0 + 13 * 32, CalcColor(-1, 1, 5, 445), 3)
      else if (y = y0) then
        screen.render(x * 8, y * 8, 1 + 13 * 32, CalcColor(-1, 1, 5, 445), 0)
      else if (y = y1) then
        screen.render(x * 8, y * 8, 1 + 13 * 32, CalcColor(-1, 1, 5, 445), 2)
      else if (x = x0) then
        screen.render(x * 8, y * 8, 2 + 13 * 32, CalcColor(-1, 1, 5, 445), 0)
      else if (x = x1) then
        screen.render(x * 8, y * 8, 2 + 13 * 32, CalcColor(-1, 1, 5, 445), 1)
      else
        screen.render(x * 8, y * 8, 2 + 13 * 32, CalcColor(5, 5, 5, 5), 1);
    end;
  end;
  draw(title, screen, x0 * 8 + 8, y0 * 8, CalcColor(5, 5, 5, 550));
end;

{ TListItem }

procedure TListItem.renderInventory(const screen: TScreen; x, y: integer);
begin
end;

{ TMenu }

procedure TMenu.init(game: TGame; input: TInputHandler);
begin
  self.input := input;
  self.game := game;
  input.ReleaseAll;
end;

function TMenu.MouseClick(const x, y: integer): Boolean;
begin
  Result := false;
end;

procedure TMenu.Tick();
begin
end;

procedure TMenu.render(screen: TScreen);
begin
end;

procedure TMenu.renderItemList(screen: TScreen; xo, yo, x1, y1: integer;
listItems: TItemList; selected: integer);
var
  renderCursor: Boolean;
  w, h, io, i0, i1: integer;
  yy, i: integer;
  item: TListItem;
begin
  renderCursor := true;
  if (selected < 0) then
  begin
    selected := -selected - 1;
    renderCursor := false;
  end;
  w := x1 - xo;
  h := y1 - yo - 1;
  i0 := 0;
  i1 := listItems.count;
  if (i1 > h) then
    i1 := h;
  io := selected - h div 2;
  if (io > listItems.count - h) then
    io := listItems.count - h;
  if (io < 0) then
    io := 0;

  for i := i0 to i1 - 1 do
  begin
    item := TListItem(listItems[i + io]);
    item.renderInventory(screen, (1 + xo) * 8, (i + 1 + yo) * 8);
  end;

  if (renderCursor) then
  begin
    yy := selected + 1 - io + yo;
    Font.draw('>', screen, (xo + 0) * 8, yy * 8, CalcColor(5, 555, 555, 555));
    Font.draw('<', screen, (xo + w) * 8, yy * 8, CalcColor(5, 555, 555, 555));
  end;
end;

{ TCraftingMenu }

function RecipeCompare(r1, r2: Pointer): integer;
begin
  if (TRecipe(r1).canCraft) and (not TRecipe(r2).canCraft) then
    Result := -1
  else if (not TRecipe(r1).canCraft) and (TRecipe(r2).canCraft) then
    Result := 1
  else
    Result := 0;
end;

constructor TCraftingMenu.create(recipes: TRecipeList; player: TPlayer);
var
  i: integer;
begin
  self.recipes := recipes;
  self.player := player;
  for i := 0 to recipes.count - 1 do
    TRecipe(recipes[i]).checkCanCraft(TPlayer(player));

{$IFDEF XE5}
  recipes.Sort(TComparer<TRecipe>.Construct(

    function(const r1, r2: TRecipe): integer
    begin
      if (r1.canCraft) and (not r2.canCraft) then
        Result := -1
      else if (not r1.canCraft) and (r2.canCraft) then
        Result := 1
      else
        Result := 0;
    end));
{$ELSE}
  recipes.Sort(RecipeCompare);
{$ENDIF}
end;

procedure TCraftingMenu.Tick();
var
  i, len: integer;
  r: TRecipe;
begin
  if (input.menu.Clicked) then
  begin
    game.setMenu(nil);
    exit;
  end;

  if (input.up.Down) then
    dec(selected);
  if (input.Down.Down) then
    inc(selected);

  len := recipes.count;
  if (len = 0) then
    selected := 0;
  if (selected < 0) then
    inc(selected, len);
  if (selected >= len) then
    dec(selected, len);

  if (input.attack.Down) and (len > 0) then
  begin
    r := recipes[selected];
    r.checkCanCraft(TPlayer(player));
    if (r.canCraft) then
    begin
      r.deductCost(TPlayer(player));
      r.craft(TPlayer(player));
      Sound.Play(secraft);
    end;
    for i := 0 to recipes.count - 1 do
      TRecipe(recipes[i]).checkCanCraft(TPlayer(player));
  end;

  input.ReleaseAll;
end;

procedure TCraftingMenu.render(screen: TScreen);
var
  recipe: TRecipe;
  i, xo, yo, hasResultItems: integer;
  requiredAmt: integer;
  costs: TResourceList;
  item: TItem;
  color: Cardinal;
  has: integer;
  List: TItemList;
begin
  Font.renderFrame(screen, 'Have', 12, 1, 19, 3);
  Font.renderFrame(screen, 'Cost', 12, 4, 19, 11);
  Font.renderFrame(screen, 'Crafting', 0, 1, 11, 11);
  List := TItemList.create;
  try
    for i := 0 to recipes.count - 1 do
      List.add(recipes[i]);
    renderItemList(screen, 0, 1, 11, 11, List, selected);
  finally
    FreeAndNil(List);
  end;

  if (recipes.count > 0) then
  begin
    recipe := recipes[selected];
    hasResultItems := TPlayer(player).inventory.count(recipe.resultTemplate);
    xo := 13 * 8;
    screen.render(xo, 2 * 8, recipe.resultTemplate.getSprite(),
      recipe.resultTemplate.getColor(), 0);
    Font.draw(inttostr(hasResultItems), screen, xo + 8, 2 * 8,
      CalcColor(-1, 555, 555, 555));

    costs := recipe.costs;
    for i := 0 to costs.count - 1 do
    begin
      item := costs[i];
      yo := (5 + i) * 8;
      screen.render(xo, yo, item.getSprite(), item.getColor(), 0);
      requiredAmt := 1;
      if (item is TResourceItem) then
        requiredAmt := TResourceItem(item).count;

      has := player.inventory.count(item);
      color := CalcColor(-1, 555, 555, 555);
      if (has < requiredAmt) then
        color := CalcColor(-1, 222, 222, 222);

      if (has > 99) then
        has := 99;
      Font.draw(inttostr(requiredAmt) + '/' + inttostr(has), screen, xo + 8,
        yo, color);
    end;
  end;
end;

{ TAboutMenu }

constructor TAboutMenu.create(parent: TMenu);
begin
  inherited create();
  self.parent := parent;
end;

function TAboutMenu.MouseClick(const x, y: integer): Boolean;
begin
  Result := true;
  game.setMenu(parent);
end;

procedure TAboutMenu.Tick();
begin
  if (input.attack.Clicked) or (input.menu.Clicked) then
  begin
    input.ReleaseAll;
    game.setMenu(parent);
  end
  else
  begin
    input.ReleaseAll;
    inc(tickCount);
{$IFDEF ANIMATEDABOUT}
    if assigned(game.miniGame) then
      game.miniGame.Tick;
{$ENDIF}
  end;
end;

procedure TAboutMenu.render(screen: TScreen);
const
  cAboutText: Array [0 .. 9] of string = ('Terracraft was inspired by',
    'Minicraft, which has been', 'published as entry for the',
    'the 22''nd ld competition.', 'Minicraft was made in 2011',
    'by Markus Persson.', 'This game was made in 2013', 'by Christian Hackbart',
    'The Source Code is ', 'available on request');
var
  col, highlight: Cardinal;
  i, j: integer;
{$IFDEF ANIMATEDABOUT}
  xScroll, yScroll: integer;
{$ENDIF}
begin
  screen.clear(0);
  col := CalcColor(0, 333, 333, 333);
  highlight := CalcColor(0, 555, 555, 555);

  Font.draw('About Terracraft', screen, -1, 8, highlight);

{$IFDEF ANIMATEDABOUT}
  if not odd(tickCount div 500) then
    j := 0
  else
    j := 4;

  for i := 0 to 3 do
    Font.draw(cAboutText[i + j], screen, -1, (2 + i) * 8, col);

  if assigned(game.miniGame) then
    with game do
    begin
      xScroll := Trunc(cos((tickCount / 3000.0) * 2 * PI) * (miniGame.w * 8) /
        2) + (miniGame.w * 8) div 2 + game.FMiniGameWidth;
      yScroll := Trunc(sin((tickCount / 3000.0) * 2 * PI) * (miniGame.h * 8) /
        2) + (miniGame.h * 8) div 2 + game.FMiniGameHeight;

      miniGame.renderBackground(miniScreen, xScroll, yScroll);
      miniGame.renderSprites(miniScreen, xScroll, yScroll);
      miniScreen.copyRect(screen, 5, 50, game.FMiniGameWidth,
        game.FMiniGameHeight);
    end;
{$ELSE}
  j := 0;
  for i := 0 to high(cAboutText) do
  begin
    if (i in [4, 6]) then
      inc(j);
    Font.draw(cAboutText[i], screen, -1, (3 + i + j) * 8, col);
  end;
{$ENDIF}
end;

{ TContainerMenu }

constructor TContainerMenu.create(player: TPlayer; title: string;
container: TInventory);
begin
  self.player := player;
  self.title := title;
  self.container := container;
  selected := 0;
  window := 0;
end;

procedure TContainerMenu.render(screen: TScreen);
var
  sel: integer;
begin
  if (window = 1) then
    screen.setOffset(6 * 8, 0);
  Font.renderFrame(screen, title, 1, 1, 12, 11);
  if window = 0 then
    sel := selected
  else
    sel := -oSelected - 1;
  renderItemList(screen, 1, 1, 12, 11, TInventory(container).Items, sel);

  Font.renderFrame(screen, 'inventory', 13, 1, 13 + 11, 11);
  if window = 1 then
    sel := selected
  else
    sel := -oSelected - 1;
  renderItemList(screen, 13, 1, 13 + 11, 11,
    TPlayer(player).inventory.Items, sel);
  screen.setOffset(0, 0);
end;

procedure TContainerMenu.Tick();
var
  tmp: integer;
  i, i2: TInventory;
  len: integer;
  item: TListItem;
begin
  if (input.menu.Clicked) then
  begin
    game.setMenu(nil);
    exit;
  end;

  if (input.left.Clicked) then
  begin
    window := 0;
    tmp := selected;
    selected := oSelected;
    oSelected := tmp;
  end;
  if (input.right.Clicked) then
  begin
    window := 1;
    tmp := selected;
    selected := oSelected;
    oSelected := tmp;
  end;

  if window = 1 then
    i := TPlayer(player).inventory
  else
    i := TInventory(container);

  if window = 0 then
    i2 := TPlayer(player).inventory
  else
    i2 := TInventory(container);

  len := i.Items.count;
  if (selected < 0) then
    selected := 0;
  if (selected >= len) then
    selected := len - 1;

  if (input.up.Clicked) then
    dec(selected);
  if (input.Down.Clicked) then
    inc(selected);

  if (len = 0) then
    selected := 0;
  if (selected < 0) then
    inc(selected, len);
  if (selected >= len) then
    dec(selected, len);

  if (input.attack.Clicked) and (len > 0) then
  begin
    item := i.Items[selected];
    i.Items.Delete(selected);
    i2.add(oSelected, item);
    if selected >= i.Items.count then
      selected := i.Items.count - 1;
  end;
  input.ReleaseAll;
end;

{ TDeadMenu }

constructor TDeadMenu.create;
begin
  inherited;
  inputDelay := 60;
end;

procedure TDeadMenu.render(screen: TScreen);
var
  seconds, minutes, hours: integer;
  timestring: string;
begin
  Font.renderFrame(screen, '', 1, 3, 19, 9);
  Font.draw('You died! Aww!', screen, 2 * 8, 4 * 8,
    CalcColor(-1, 555, 555, 555));

  seconds := game.gametime div 60;
  minutes := seconds div 60;
  hours := minutes div 60;
  minutes := minutes mod 60;
  seconds := seconds mod 60;

  if (hours > 0) then
    timestring := inttostr(hours) + 'h' + inttostr(minutes) + 'm'
  else
    timestring := inttostr(minutes) + 'm ' + inttostr(seconds) + 's';

  Font.draw('Time:', screen, 2 * 8, 5 * 8, CalcColor(-1, 555, 555, 555));
  Font.draw(timestring, screen, (2 + 5) * 8, 5 * 8,
    CalcColor(-1, 550, 550, 550));
  Font.draw('Score:', screen, 2 * 8, 6 * 8, CalcColor(-1, 555, 555, 555));
  Font.draw(inttostr(TPlayer(game.player).score), screen, (2 + 6) * 8, 6 * 8,
    CalcColor(-1, 550, 550, 550));
  Font.draw('Press red to lose', screen, 2 * 8, 8 * 8,
    CalcColor(-1, 333, 333, 333));
end;

function TDeadMenu.MouseClick(const x, y: integer): Boolean;
begin
  if IsInRect(1, 3, 19, 9, x, y) then
  begin
    Result := true;
    game.setMenu(TTitleMenu.create);
  end
  else
    Result := false;
end;

procedure TDeadMenu.Tick;
begin
  if (inputDelay > 0) then
    dec(inputDelay)
  else if (input.attack.Clicked) or (input.menu.Clicked) then
  begin
    input.ReleaseAll;
    game.setMenu(TTitleMenu.create);
  end;
end;

{ TWonMenu }

constructor TWonMenu.create;
begin
  inherited;
  inputDelay := 60;
end;

function TWonMenu.MouseClick(const x, y: integer): Boolean;
begin
  if IsInRect(1, 3, 19, 9, x, y) then
  begin
    Result := true;
    game.setMenu(TTitleMenu.create);
  end
  else
    Result := false;
end;

procedure TWonMenu.Tick();
begin
  if (inputDelay > 0) then
    dec(inputDelay)
  else if (input.attack.Clicked) or (input.menu.Clicked) then
    game.setMenu(TTitleMenu.create)
  else
    input.ReleaseAll;
end;

procedure TWonMenu.render(screen: TScreen);
var
  seconds, minutes, hours: integer;
  timestring: string;
begin
  Font.renderFrame(screen, '', 1, 3, 19, 9);
  Font.draw('You won! Yay!', screen, 2 * 8, 4 * 8,
    CalcColor(-1, 555, 555, 555));

  seconds := game.gametime div 60;
  minutes := seconds div 60;
  hours := minutes div 60;
  minutes := minutes mod 60;
  seconds := seconds mod 60;

  if (hours > 0) then
    timestring := inttostr(hours) + 'h' + inttostr(minutes) + 'm'
  else
    timestring := inttostr(minutes) + 'm ' + inttostr(seconds) + 's';

  Font.draw('Time:', screen, 2 * 8, 5 * 8, CalcColor(-1, 555, 555, 555));
  Font.draw(timestring, screen, (2 + 5) * 8, 5 * 8,
    CalcColor(-1, 550, 550, 550));
  Font.draw('Score:', screen, 2 * 8, 6 * 8, CalcColor(-1, 555, 555, 555));
  Font.draw(inttostr(TPlayer(game.player).score), screen, (2 + 6) * 8, 6 * 8,
    CalcColor(-1, 550, 550, 550));
  Font.draw('Press red to win', screen, 2 * 8, 8 * 8,
    CalcColor(-1, 333, 333, 333));
end;

{ TTitleMenu }

constructor TTitleMenu.create;
begin
  inherited;
  selected := 0;
  options[0] := 'Start game';
  options[1] := 'How to play';
  options[2] := 'About';
end;

function TTitleMenu.MouseClick(const x, y: integer): Boolean;
var
  i: integer;
  x1, x2: integer;
begin
  Result := false;
  for i := 0 to 2 do
  begin
    if (y >= (6 + 2 * i) * 8) and (y <= (6 + 2 * (i + 1)) * 8) then
    begin
      x2 := length(options[i]) * 8;
      x1 := (game.screen.w - x2) div 2;
      if (x >= x1) and (x <= x1 + x2) then
      begin
        Result := true;
        if selected = i then
          ClickSelect()
        else
          selected := i;
        exit;
      end;
    end;
  end;
end;

procedure TTitleMenu.render(screen: TScreen);
var
  w, h, xo, yo: integer;
  y, x, i: integer;
  msg: string;
  titlecolor, col: Cardinal;
begin
  screen.clear(0);

  h := 2;
  w := 17;
  titlecolor := CalcColor(0, 010, 131, 551);
  xo := (screen.w - w * 8) div 2;
  yo := 16;
  for y := 0 to h - 1 do
    for x := 0 to w - 1 do
      screen.render(xo + x * 8, yo + y * 8, x + (y + 6) * 32, titlecolor, 0);

  for i := 0 to 2 do
  begin
    msg := options[i];
    col := CalcColor(0, 222, 222, 222);
    if (i = selected) then
    begin
      msg := '> ' + msg + ' <';
      col := CalcColor(0, 555, 555, 555);
    end;
    Font.draw(msg, screen, -1, (6 + 2 * i) * 8, col);
  end;

  Font.draw('(use virtual stick to play)', screen, -1, screen.h - 8,
    CalcColor(0, 111, 111, 111));
end;

procedure TTitleMenu.ClickSelect();
begin
  input.ReleaseAll;
  if (selected = 0) then
  begin
    Sound.Play(seClick);
    game.resetGame;
    game.setMenu(nil);
  end;
  if (selected = 1) then
    game.setMenu(TInstructionsMenu.create(self));
  if (selected = 2) then
    game.setMenu(TAboutMenu.create(self));
end;

procedure TTitleMenu.Tick();
var
  len: integer;
begin
  if (input.up.Down) then
    dec(selected);
  if (input.Down.Down) then
    inc(selected);

  len := length(options);
  if (selected < 0) then
    selected := selected + len;
  if (selected >= len) then
    selected := selected - len;

  if (input.attack.Clicked) or (input.menu.Clicked) then
    ClickSelect()
  else
    input.ReleaseAll;
end;

{ TInstructionsMenu }

constructor TInstructionsMenu.create(parent: TMenu);
begin
  self.parent := parent;
end;

function TInstructionsMenu.MouseClick(const x, y: integer): Boolean;
begin
  Result := true;
  game.setMenu(parent);
end;

procedure TInstructionsMenu.Tick();
begin
  if (input.attack.Clicked) or (input.menu.Clicked) then
  begin
    input.ReleaseAll;
    game.setMenu(parent);
  end;
end;

procedure TInstructionsMenu.render(screen: TScreen);
var
  x: integer;
  header, col: Cardinal;
begin
  screen.clear(0);

  header := CalcColor(0, 555, 555, 555);
  col := CalcColor(0, 333, 333, 333);
  x := 0 * 8 + 4;

  Font.draw('HOW TO PLAY', screen, -1, 8, header);
  Font.draw('Control your character with', screen, x, 3 * 8, col);
  Font.draw('the joystick.', screen, x, 4 * 8, col);
  Font.draw('Attack enemies by pressing', screen, x, 5 * 8, col);
  Font.draw('the red button. A click on', screen, x, 6 * 8, col);
  Font.draw('the green button open your', screen, x, 7 * 8, col);
  Font.draw('your inventory.', screen, x, 8 * 8, col);
  Font.draw('Select an item in the list', screen, x, 9 * 8, col);
  Font.draw('to equip the player.', screen, x, 10 * 8, col);
  Font.draw('The workbench can be used', screen, x, 11 * 8, col);
  Font.draw('for assembling utilities.', screen, x, 12 * 8, col);
  Font.draw('Aim of the game is to', screen, x, 14 * 8, col);
  Font.draw('defeat the air wizard.', screen, x, 15 * 8, col);
end;


{ LevelTransitionMenu }

constructor TLevelTransitionMenu.create(dir: integer);
begin
  inherited create;
  self.dir := dir;
  time := 0;
end;

procedure TLevelTransitionMenu.Tick();
begin
  inc(time, 2);
  if (time = 30) then
    game.changeLevel(dir);
  if (time = 60) then
    game.setMenu(nil);
end;

procedure TLevelTransitionMenu.render(screen: TScreen);
var
  dd, x, y: integer;
begin
  for x := 0 to 19 do
    for y := 0 to 14 do
    begin
      dd := (y + x mod 2 * 2 + x div 3) - time;
      if (dd < 0) and (dd > -30) then
      begin
        if (dir > 0) then
          screen.render(x * 8, y * 8, 0, 0, 0)
        else
          screen.render(x * 8, screen.h - y * 8 - 8, 0, 0, 0);
      end;
    end;
end;

{ TInventoryMenu }

constructor TInventoryMenu.create(player: TPlayer);
begin
  inherited create;
  self.player := player;
  selected := 0;
  if (TPlayer(player).activeItem <> nil) then
  begin
    TPlayer(player).inventory.Items.insert(0, TPlayer(player).activeItem);
    TPlayer(player).activeItem := nil;
  end;
end;

procedure TInventoryMenu.Tick();
var
  len: integer;
  item: TItem;
  Down: Boolean;
begin
  if (input.menu.Down) then
  begin
    game.setMenu(nil);
    exit;
  end;

  if (input.up.Clicked) then
    dec(selected);
  if (input.Down.Clicked) then
    inc(selected);

  len := TPlayer(player).inventory.Items.count;
  if (len = 0) then
    selected := 0;
  if (selected < 0) then
    inc(selected, len);
  if (selected >= len) then
    dec(selected, len);

  Down := input.attack.Clicked;
  input.ReleaseAll;
  if (Down) and (len > 0) then
  begin
    item := TItem(player.inventory.Items[selected]);
    player.inventory.Items.Delete(selected);
    player.activeItem := item;
    game.setMenu(nil);
  end;
end;

procedure TInventoryMenu.render(screen: TScreen);
begin
  Font.renderFrame(screen, 'inventory', 1, 1, 12, 11);
  renderItemList(screen, 1, 1, 12, 11, player.inventory.Items, selected);
end;

// ----- Game ------------------------------------------------------------------

{ TKey }

procedure TKey.Toggle(const pressed: Boolean);
begin
  if (pressed <> FDown) then
    FDown := pressed;
  if (pressed) then
    inc(FPresses);
end;

procedure TKey.Tick;
begin
  if (FAbsorbs < FPresses) then
  begin
    inc(FAbsorbs);
    FClicked := true;
  end
  else
    FClicked := false;
end;

procedure TKey.Release;
begin
  FDown := false;
end;

constructor TKey.create;
begin
  FPresses := 0;
  FAbsorbs := 0;
  FDown := false;
  FClicked := false;
end;

{ TInputHandler }

constructor TInputHandler.create;
begin
  up := TKey.create;
  Down := TKey.create;
  left := TKey.create;
  right := TKey.create;
  menu := TKey.create;
  attack := TKey.create;
end;

procedure TInputHandler.ReleaseAll;
begin
  up.Release;
  Down.Release;
  left.Release;
  right.Release;
  menu.Release;
  attack.Release;
end;

procedure TInputHandler.Tick;
begin
  up.Tick;
  Down.Tick;
  left.Tick;
  right.Tick;
  menu.Tick;
  attack.Tick;
end;

destructor TInputHandler.Destroy;
begin
  FreeAndNil(up);
  FreeAndNil(Down);
  FreeAndNil(left);
  FreeAndNil(right);
  FreeAndNil(menu);
  FreeAndNil(attack);
  inherited;
end;

procedure TInputHandler.Toggle(Key: Word; pressed: Boolean);
begin
  case Key of
    119, 87, 38:
      up.Toggle(pressed); // W
    115, 83, 40:
      Down.Toggle(pressed); // S
    97, 65, 37:
      left.Toggle(pressed); // A
    100, 68, 39:
      right.Toggle(pressed); // D
    120, 88, 13:
      menu.Toggle(pressed); // Enter, X
    32, 99, 67:
      attack.Toggle(pressed); // C, SPACE
  end;
end;

{ TGame }

constructor TGame.create(const Width, Height: integer;
const Graphics: TGamePixelBuffer; const GameWidth, GameHeight: integer);
var
  pp, r, g, b: integer;
  rr, gg, bb, mid: integer;
  r1, g1, b1: integer;
begin
  inherited create(true);
  FogOfWar := false;
  FInitGame := true;

{$IFDEF XE5}
  FCriticalSection := TCriticalSection.create;
{$ELSE}
  InitializeCriticalSection(FCriticalSection);
{$ENDIF}
  hasFocus := true;
  FLastTime := 0;

  tickCount := 0;
  gametime := 0;
  currentLevel := 3;
  FGameWidth := GameWidth;
  FGameHeight := GameHeight;

{$IFDEF ANIMATEDABOUT}
  FMiniGameWidth := (Trunc(FGameWidth * 0.98) div 8) * 8;
  FMiniGameHeight := (Trunc(FGameHeight / 2.2) div 8) * 8;
{$ENDIF}
  Setlength(FPixels, FGameWidth * FGameHeight);
  input := TInputHandler.create;

  pp := 0;
  for r := 0 to 5 do
  begin
    for g := 0 to 5 do
    begin
      for b := 0 to 5 do
      begin
        rr := (r * 255 div 5);
        gg := (g * 255 div 5);
        bb := (b * 255 div 5);
        mid := (rr * 30 + gg * 59 + bb * 11) div 100;

        r1 := ((rr + mid * 1) div 2) * 230 div 255 + 10;
        g1 := ((gg + mid * 1) div 2) * 230 div 255 + 10;
        b1 := ((bb + mid * 1) div 2) * 230 div 255 + 10;
        colors[pp] := r1 shl 16 or g1 shl 8 or b1;
        inc(pp);
      end;
    end;
  end;

  screen := TScreen.create(FGameWidth, FGameHeight, TSpriteSheet.create(Width,
    Height, Graphics));

  lightScreen := TScreen.create(FGameWidth, FGameHeight,
    TSpriteSheet.create(Width, Height, Graphics));
{$IFDEF ANIMATEDABOUT}
  miniScreen := TScreen.create(FMiniGameWidth, FMiniGameHeight,
    TSpriteSheet.create(Width, Height, Graphics));
{$ENDIF}
  Suspended := false;
end;

destructor TGame.Destroy;
begin
  Suspended := false;

  Terminate;
  WaitFor;

  FreeLevels;
  Setlength(FPixels, 0);
  FreeAndNil(FMenu);
  FreeAndNil(screen);
  FreeAndNil(lightScreen);

  FreeAndNil(input);

{$IFDEF ANIMATEDABOUT}
  FreeAndNil(miniScreen);
  FreeAndNil(miniGame);
{$ENDIF}
{$IFDEF XE5}
  FreeAndNil(FCriticalSection);
{$ELSE}
  DeleteCriticalSection(FCriticalSection);
{$ENDIF}
  inherited;
end;

procedure TGame.FreeLevels;
var
  i: integer;
begin
  for i := 0 to high(levels) do
    FreeAndNil(levels[i]);
end;

procedure TGame.setMenu(menu: TMenu);
begin
  if menu = nil then
    input.ReleaseAll;

{$IFNDEF NEXTGEN}
  if (not(menu is TAboutMenu)) and (not(menu is TInstructionsMenu)) then
{$ENDIF}
    FreeAndNil(FMenu);
  FMenu := menu;

  if FMenu <> nil then
    FMenu.init(self, input);
end;

procedure TGame.Loading(const Percentage: integer);

const
  cGarbageStatus: Array [0 .. 5] of string = ('assembling trees',
    'adding flowers', 'painting colors', 'creating enemies', 'digging holes',
    'placing water');

var
  i: integer;
  Str: string;
begin
  Str := '';
  for i := 0 to Percentage div 10 do
    Str := Str + '.';
  while length(Str) < 10 do
    Str := Str + ' ';

  Str := 'Loading (' + Str + ')';
  render([Str, '', cGarbageStatus[random(high(cGarbageStatus))]]);
end;

procedure TGame.resetGame;
var
  i: integer;
begin
  playerDeadTime := 0;
  wonTimer := 0;
  gametime := 0;
  hasWon := false;

  if (not assigned(player)) or (player.removed) then
  begin
    FreeLevels;

    currentLevel := 3;
    Loading(0);

    levels[4] := TLevel.create(128, 128, 1, nil);
    Loading(20);

    levels[3] := TLevel.create(128, 128, 0, levels[4]);
    Loading(30);

    levels[2] := TLevel.create(128, 128, -1, levels[3]);
    Loading(40);

    levels[1] := TLevel.create(128, 128, -2, levels[2]);
    Loading(70);

    levels[0] := TLevel.create(128, 128, -3, levels[1]);
    Loading(90);

    level := levels[currentLevel];
    player := TPlayer.create(self, input);
    player.findStartPos(level);
    level.add(player);
    for i := 0 to high(levels) do
      levels[i].trySpawn(5000);
  end;
end;

procedure TGame.Tick();
var
  tmp: integer;
begin
  inc(tickCount);

  if (not hasFocus) then
  begin
    input.ReleaseAll();
    exit;
  end;

  if assigned(player) and (not player.removed) and (not hasWon) then
    inc(gametime);

  input.Tick();

  if (FMenu <> nil) then
  begin
    FMenu.Tick();
  end
  else
  begin
    if (player.removed) then
    begin
      inc(playerDeadTime);
      if (playerDeadTime > 60) then
      begin
        setMenu(TDeadMenu.create);
        exit;
      end;
    end
    else
    begin
      tmp := pendingLevelChange;
      if (tmp <> 0) then
      begin
        pendingLevelChange := 0;
        setMenu(TLevelTransitionMenu.create(tmp));
        exit;
      end;
    end;

    if (wonTimer > 0) then
    begin
      FreeAndNil(player);
      dec(wonTimer);
      if wonTimer = 0 then
      begin
        setMenu(TWonMenu.create);
        exit;
      end;

    end;
    level.Tick();
  end;
end;

procedure TGame.changeLevel(dir: integer);
begin
  level.remove(player);
  inc(currentLevel, dir);
  level := levels[currentLevel];
  player.x := (player.x shr 4) * 16 + 8;
  player.y := (player.y shr 4) * 16 + 8;
  level.add(player);
end;

procedure TGame.renderGui(const Messages: Array of String);
var
  i, x, y: integer;

  procedure DrawTitle;
  var
    h, w, xo, yo, x, y: integer;
    titlecolor: Cardinal;
  begin
    h := 2;
    w := 17;
    titlecolor := CalcColor(0, 010, 131, 551);
    xo := (screen.w - w * 8) div 2;
    yo := 16;
    for y := 0 to h - 1 do
      for x := 0 to w - 1 do
        screen.render(xo + x * 8, yo + y * 8, x + (y + 6) * 32, titlecolor, 0);
  end;

begin
  if high(Messages) > -1 then
  begin
    screen.clear(0);
    DrawTitle;
    for i := 0 to high(Messages) do
      Font.draw(Messages[i], screen, -1, 60 + i * 8,
        CalcColor(0, 333, 333, 333));
    exit;
  end;

  for y := 0 to 1 do
    for x := 0 to (FGameWidth shr 3) - 1 do
      screen.render(x * 8, screen.h - 16 + y * 8, 0 + 12 * 32,
        CalcColor(000, 000, 000, 000), 0);

  if assigned(player) then
  begin
    for i := 0 to 9 do
    begin
      if (i < player.health) then
        screen.render(i * 8, screen.h - 16, 0 + 12 * 32,
          CalcColor(000, 200, 500, 533), 0)
      else
        screen.render(i * 8, screen.h - 16, 0 + 12 * 32,
          CalcColor(000, 100, 000, 000), 0);

      if (player.staminaRechargeDelay > 0) then
      begin
        if (player.staminaRechargeDelay div 4) mod 2 = 0 then
          screen.render(i * 8, screen.h - 8, 1 + 12 * 32,
            CalcColor(000, 555, 000, 000), 0)
        else
          screen.render(i * 8, screen.h - 8, 1 + 12 * 32,
            CalcColor(000, 110, 000, 000), 0);
      end
      else
      begin
        if (i < player.stamina) then
          screen.render(i * 8, screen.h - 8, 1 + 12 * 32,
            CalcColor(000, 220, 550, 553), 0)
        else
          screen.render(i * 8, screen.h - 8, 1 + 12 * 32,
            CalcColor(000, 110, 000, 000), 0);
      end
    end;
    if (player.activeItem <> nil) then
      player.activeItem.renderInventory(screen, 10 * 8, screen.h - 16);
  end;

  if (FMenu <> nil) then
    FMenu.render(screen);
end;

procedure TGame.renderFocusNagger();
var
  msg: string;
  x, y, xx, yy, w, h: integer;
begin
  msg := 'Click to focus!';
  w := length(msg);
  h := 1;
  xx := (FGameWidth - w * 8) div 2;
  yy := (FGameHeight - 8) div 2;

  screen.render(xx - 8, yy - 8, 0 + 13 * 32, CalcColor(-1, 1, 5, 445), 0);
  screen.render(xx + w * 8, yy - 8, 0 + 13 * 32, CalcColor(-1, 1, 5, 445), 1);
  screen.render(xx - 8, yy + 8, 0 + 13 * 32, CalcColor(-1, 1, 5, 445), 2);
  screen.render(xx + w * 8, yy + 8, 0 + 13 * 32, CalcColor(-1, 1, 5, 445), 3);
  for x := 0 to w - 1 do
  begin
    screen.render(xx + x * 8, yy - 8, 1 + 13 * 32, CalcColor(-1, 1, 5, 445), 0);
    screen.render(xx + x * 8, yy + 8, 1 + 13 * 32, CalcColor(-1, 1, 5, 445), 2);
  end;

  for y := 0 to h - 1 do
  begin
    screen.render(xx - 8, yy + y * 8, 2 + 13 * 32, CalcColor(-1, 1, 5, 445), 0);
    screen.render(xx + w * 8, yy + y * 8, 2 + 13 * 32,
      CalcColor(-1, 1, 5, 445), 1);
  end;

  if ((tickCount div 20) mod 2 = 0) then
    Font.draw(msg, screen, xx, yy, CalcColor(5, 333, 333, 333))
  else
    Font.draw(msg, screen, xx, yy, CalcColor(5, 555, 555, 555));
end;

procedure TGame.scheduleLevelChange(dir: integer);
begin
  pendingLevelChange := dir;
end;

procedure TGame.won();
begin
  wonTimer := 60 * 3;
  hasWon := true;
end;

function TGame.GetMenuVisible(): Boolean;
begin
  Result := assigned(FMenu);
end;

function TGame.MouseClick(const x, y: integer): Boolean;
begin
  if assigned(FMenu) then
    Result := FMenu.MouseClick(x, y)
  else
    Result := false;
end;

procedure TGame.RenderBitmap(const Bitmap: TBitmap);
{$IFDEF XE5}
var
  y: integer;
  line: PAlphaColorArray;
  data: TBitmapData;
begin
  FCriticalSection.Enter;
  try
    Bitmap.SetSize(FGameWidth, FGameHeight);
{$IFDEF XE7}
    Bitmap.map(TMapAccess.Write, data);
{$ELSE}
    Bitmap.map(TMapAccess.maWrite, data);
{$ENDIF}

    try
      for y := 0 to FGameHeight - 1 do
      begin
        line := data.GetScanline(y);
        move(FPixels[FGameWidth * y], line^, FGameWidth * 4);
      end;
    finally
      Bitmap.Unmap(data);
    end;
  finally
    FCriticalSection.Leave;
  end;
end;
{$ELSE}

var
  i, x, y: integer;
  line: PDWord;
begin
  EnterCriticalSection(FCriticalSection);
  try
    Bitmap.Width := GAME_WIDTH;
    Bitmap.Height := GAME_HEIGHT;
    Bitmap.PixelFormat := pf32bit;
    i := 0;
    for y := 0 to GAME_HEIGHT - 1 do
    begin
      line := Bitmap.ScanLine[y];
      for x := 0 to GAME_WIDTH - 1 do
      begin
        line^ := FPixels[i];
        inc(i);
        inc(line);
      end;
    end;
  finally
    LeaveCriticalSection(FCriticalSection);
  end;
end;
{$ENDIF}

procedure TGame.render(const Messages: Array of String);
var
  x, y, xScroll, yScroll: integer;
  cc, col: Cardinal;
begin
  if assigned(player) then
  begin
    xScroll := player.x - screen.w div 2;
    yScroll := player.y - (screen.h - 8) div 2;
    if (xScroll < 16) then
      xScroll := 16;
    if (yScroll < 16) then
      yScroll := 16;
    if (xScroll > level.w * 16 - screen.w - 16) then
      xScroll := level.w * 16 - screen.w - 16;
    if (yScroll > level.h * 16 - screen.h - 16) then
      yScroll := level.h * 16 - screen.h - 16;
    if (currentLevel > 3) then
    begin
      col := CalcColor(20, 20, 121, 121);
      for y := 0 to 13 do
        for x := 0 to 23 do
        begin
          screen.render(x * 8 - ((xScroll div 4) and 7),
            y * 8 - ((yScroll div 4) and 7), 0, col, 0);
        end;
    end;

    level.renderBackground(screen, xScroll, yScroll);
    level.renderSprites(screen, xScroll, yScroll);

    if (currentLevel < 3) or (FogOfWar) then
    begin
      lightScreen.clear(0);
      if currentLevel < 3 then // Underground
        level.renderLight(lightScreen, xScroll, yScroll)
      else
        level.renderFog(lightScreen, lightScreen, xScroll, yScroll);
      screen.overlay(lightScreen, xScroll, yScroll);
    end;
  end;

  renderGui(Messages);

  if assigned(input) and (not hasFocus) then
  begin
    input.ReleaseAll;
    renderFocusNagger();
  end;

{$IFDEF XE5}
  FCriticalSection.Enter;
{$ELSE}
  EnterCriticalSection(FCriticalSection);
{$ENDIF}
  try
    for y := 0 to screen.h - 1 do
    begin
      for x := 0 to screen.w - 1 do
      begin
        cc := screen.pixels[x + y * screen.w];
        if (cc < 255) then
        begin
{$IFNDEF MSWINDOWS}
          FPixels[x + y * FGameWidth] := RGBToBGR(colors[cc]) or $FF000000;
{$ELSE}
          FPixels[x + y * FGameWidth] := colors[cc] or $FF000000;
{$ENDIF}
        end;
      end;
    end;
  finally
{$IFDEF XE5}
    FCriticalSection.Leave;
{$ELSE}
    LeaveCriticalSection(FCriticalSection);
{$ENDIF}
  end;
end;

function TGame.GetDayCycle(): single;
var
  dayticks: integer;
begin
  // the game time is shifted by a few hours so we start in the morning
  dayticks := (gametime + DAY_LENGTH div 4) mod DAY_LENGTH;
  Result := dayticks / DAY_LENGTH;
end;

procedure TGame.Execute;
var
  differ: Cardinal;
begin
  if FInitGame then
  begin
    resetGame;
{$IFDEF ANIMATEDABOUT}
    miniGame := TLevel.create(128, 128, 0, nil);
    miniGame.trySpawn(10000);
{$ENDIF}
    setMenu(TTitleMenu.create);
    FInitGame := false;
  end;

  while not terminated do
  begin
    differ := GetTickCount - FLastTime;
    if differ > 16 then
    begin
      Tick;
      FLastTime := GetTickCount;
      render([]);
    end;
    sleep(2);
  end;
end;

initialization

finalization

FreeAndNil(FResources);
FreeAndNil(FTooltypes);
FreeAndNil(FCrafting);
FreeAndNil(FFont);

end.
