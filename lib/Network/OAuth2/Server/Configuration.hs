{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

-- | Description: Configuration parsing.
module Network.OAuth2.Server.Configuration where

import           Control.Applicative
import           Data.Configurator           as C
import           Data.Configurator.Types
import           Data.String

import           Network.OAuth2.Server.Types

defaultServerOptions :: ServerOptions
defaultServerOptions =
    let optDBString = ""
        optStatsHost = "localhost"
        optStatsPort = 8888
        optServiceHost = "*"
        optServicePort = 8080
        optUIPageSize = 10
        optVerifyRealm = "verify-token"
    in ServerOptions{..}

loadOptions :: Config -> IO ServerOptions
loadOptions conf = do
    optDBString <- ldef optDBString "database"
    optStatsHost <- ldef optStatsHost "stats.host"
    optStatsPort <- ldef optStatsPort "stats.port"
    optServiceHost <- maybe (optServiceHost defaultServerOptions) fromString <$> C.lookup conf "api.host"
    optServicePort <- ldef optServicePort "api.port"
    optUIPageSize <- ldef optUIPageSize "ui.page_size"
    optVerifyRealm <- ldef optVerifyRealm "api.verify_realm"
    return ServerOptions{..}
  where
    ldef f k = lookupDefault (f defaultServerOptions) conf k
