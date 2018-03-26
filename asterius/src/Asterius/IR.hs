{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE StrictData #-}
{-# LANGUAGE TypeFamilies #-}

module Asterius.IR
  ( ModSym(..)
  , StaticSym(..)
  , FuncSym(..)
  , BlockSym(..)
  , AsteriusIR
  , MarshalError(..)
  , marshalIR
  ) where

import qualified CLabel as GHC
import qualified Cmm as GHC
import Control.Monad.Except
import qualified Data.ByteString.Short as SBS
import Data.Hashable
import Data.Serialize
import Data.Traversable
import GHC.Exts
import GHC.Generics
import Language.Haskell.GHC.Toolkit.Compiler
import Language.WebAssembly.IR

newtype ModSym =
  ModSym SBS.ShortByteString

deriving instance Show ModSym

deriving instance Eq ModSym

deriving instance Generic ModSym

instance Hashable ModSym

instance Serialize ModSym

data StaticSym =
  StaticSym ModSym
            SBS.ShortByteString

deriving instance Show StaticSym

deriving instance Eq StaticSym

deriving instance Generic StaticSym

instance Hashable StaticSym

instance Serialize StaticSym

data FuncSym =
  FuncSym ModSym
          SBS.ShortByteString

deriving instance Show FuncSym

deriving instance Eq FuncSym

deriving instance Generic FuncSym

instance Hashable FuncSym

instance Serialize FuncSym

data BlockSym =
  BlockSym FuncSym
           Int

deriving instance Show BlockSym

deriving instance Eq BlockSym

deriving instance Generic BlockSym

instance Hashable BlockSym

instance Serialize BlockSym

data AsteriusIR

instance IRSpec AsteriusIR where
  type ModuleSymbol AsteriusIR = ModSym
  type StaticSymbol AsteriusIR = StaticSym
  type FunctionSymbol AsteriusIR = FuncSym
  type BlockSymbol AsteriusIR = BlockSym

data MarshalError =
  MarshalError

deriving instance Show MarshalError

marshalIR :: MonadError MarshalError m => IR -> m (Module AsteriusIR)
marshalIR IR {..} = mconcat <$> for cmmRaw marshalRawCmmDecl

marshalRawCmmDecl ::
     MonadError MarshalError m => GHC.RawCmmDecl -> m (Module AsteriusIR)
marshalRawCmmDecl decl =
  case decl of
    GHC.CmmData _ (GHC.Statics sym ss) -> marshalCmmData sym ss
    GHC.CmmProc _ sym _ graph -> marshalCmmProc sym graph

marshalCmmData ::
     MonadError MarshalError m
  => GHC.CLabel
  -> [GHC.CmmStatic]
  -> m (Module AsteriusIR)
marshalCmmData sym ss = do
  ses <- for ss marshalCmmStatic
  pure
    mempty
      {statics = [(undefined, Static {align = 8, elements = fromList ses})]}

marshalCmmStatic ::
     MonadError MarshalError m => GHC.CmmStatic -> m (StaticElement AsteriusIR)
marshalCmmStatic s =
  case s of
    GHC.CmmStaticLit lit -> undefined
    GHC.CmmUninitialised len -> pure $ Uninitialized len
    GHC.CmmString ws -> pure $ BufferElement $ SBS.pack ws <> "\0"

marshalCmmProc ::
     MonadError MarshalError m
  => GHC.CLabel
  -> GHC.CmmGraph
  -> m (Module AsteriusIR)
marshalCmmProc = undefined
