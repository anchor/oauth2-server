{-# LANGUAGE OverloadedStrings #-}

module Main where

import           Control.Applicative
import           Control.Exception
import           Control.Lens
import           Data.Aeson.Lens
import           Data.Either
import           Data.Monoid
import qualified Data.Text.Encoding    as T
import           Network.HTTP.Client   (HttpException)
import           Network.Wreq
import           System.Environment
import           Test.Hspec

import           Network.OAuth2.Server

type URI = String

main :: IO ()
main = do
    args <- getArgs
    case args of
        ('h':'t':'t':'p':'s':':':'/':'/':uri):rest -> withArgs rest $ hspec (tests $ "https://"<>uri)
        ('h':'t':'t':'p':':':'/':'/':uri):rest -> withArgs rest $ hspec (tests $ "http://"<>uri)
        _ -> putStrLn "First argument must be a server URI."

tests :: String -> Spec
tests base_uri = do
    describe "token endpoint" $ do
        it "uses the same details when refreshing a token"
            pending

        it "revokes the existing token when it is refreshed"
            pending

        it "restricts new tokens to the client which granted them"
            pending

    describe "verify endpoint" $ do

        it "returns a response when given valid credentials and a matching token" $ do
            resp <- verifyToken base_uri client1 (fst tokenVV)
            resp `shouldSatisfy` isRight

        it "returns an error when given valid credentials and a token from another client" $ do
            resp <- verifyToken base_uri client2 (fst tokenVV)
            resp `shouldSatisfy` isLeft

        it "returns an error when given invalid client credentials" $ do
            resp <- verifyToken base_uri client3 (fst tokenVV)
            resp `shouldSatisfy` isLeft

        it "returns an error when given a token which has been revoked" $ do
            resp <- verifyToken base_uri client1 (fst tokenRV)
            resp `shouldSatisfy` isLeft

        it "returns an error when given a token which is not valid" $ do
            resp <- verifyToken base_uri client1 (fst tokenDERP)
            resp `shouldSatisfy` isLeft

    describe "authorize endpoint" $ do
        it "returns an error when Shibboleth authentication headers are missing"
            pending

        it "displays the details of the token to be approved"
            pending

        it "includes an identifier for the code request"
            pending

        it "the POST returns an error when Shibboleth authentication headers are missing"
            pending

        it "the POST returns an error when the request ID is missing"
            pending

        it "the POST returns an error when the Shibboleth authentication headers identify a mismatched user"
            pending

        it "the POST returns a redirect when approved"
            pending

        it "the redirect contains a code which can be used to request a token"
            pending

    describe "user interface" $ do
        it "returns an error when Shibboleth authentication headers are missing"
            pending

        it "displays a list of the users tokens"
            pending

        it "includes a revoke link for each token"
            pending

        it "allows the user to revoke a token"
            pending

-- | Use the verify endpoint of a token server to verify a token.
verifyToken :: URI -> (ClientID, Password) -> Token -> IO (Either String AccessResponse)
verifyToken base_uri (client,secret) tok = do

    let opts = defaults & header "Accept" .~ ["application/json"]
                        & header "Content-Type" .~ ["application/octet-stream"]
                        & auth ?~ basicAuth user pass

    putStrLn $ "Contacting " <> endpoint <> " to validate " <> show tok <> " for " <> show client
    r <- try (postWith opts endpoint body)
    case r of
        Left e  -> return . Left . show $ (e :: HttpException)
        Right v ->
            return $ case v ^? responseBody . _JSON of
                Nothing -> Left "Could not decode response."
                Just tr  -> Right tr
  where
    user = review clientID client
    pass = T.encodeUtf8 $ review password secret
    body = review token tok
    endpoint = base_uri <> "/oauth2/verify"

-- * Fixtures
--
-- $ These values refer to clients and tokens defined in the database fixture.

-- ** Clients
--
-- $ Clients are identified by their client_id and client_secret.

client1 :: (ClientID, Password)
client1 =
    let Just i = preview clientID "5641ea27-1111-1111-1111-8fc06b502be0"
        Just p = preview password "clientpassword1"
    in (i,p)

-- | 'client1' with an incorrect password.
client1bad :: (ClientID, Password)
client1bad =
    let Just p = preview password "clientpassword1bad"
    in const p <$> client1

client2 :: (ClientID, Password)
client2 =
    let Just i = preview clientID "5641ea27-2222-2222-2222-8fc06b502be0"
        Just p = preview password "clientpassword2"
    in (i,p)

-- | 'client2' with an incorrect password.
client2bad :: (ClientID, Password)
client2bad =
    let Just p = preview password "clientpassword2bad"
    in const p <$> client2

-- | A non-existant client.
client3 :: (ClientID, Password)
client3 =
    let Just i = preview clientID "5641ea27-3333-3333-3333-8fc06b502be0"
        Just p = preview password "clientpassword3"
    in (i,p)

-- ** Tokens
--
-- $ Tokens pre-defined in the fixture database. These pairs contain the bearer
-- and refresh token in that order and are named for the status of these tokens
-- (V, E, and R mean valid, expired, and revoked respectively).
--
-- All of these tokens are valid for 'client1' above.

tokenVV :: (Token, Token)
tokenVV =
    let Just b = preview token "Xnl4W3J3ReJYN9qH1YfR4mjxaZs70lVX/Edwbh42KPpmlqhp500c4UKnQ6XKmyjbnqoRW1NFWl7h"
        Just r = preview token "hBC86fa6py9nDYMNNZAOfkseAJlN5WvnEmelbCuAUOqOYhYan8N7EgZh6b6k7DpWF6j9DomLlaGZ"
    in (b,r)

tokenEV :: (Token, Token)
tokenEV =
    let Just b = preview token "4Bb+zZV3cizc4kIiWwxxKxj4nRxBdyvB3aWgfqsq8u9h+Y9uqP6NJTtcLWLZaxmjl+oqn+bHObJU"
        Just r = preview token "l5lXecbLVcUvE25fPHbMpJnK0IY6wta9nKId60Q06HY4fYkx5b3djFwU2xtA9+NDK3aPdaByNXFC"
    in (b,r)

tokenEE :: (Token, Token)
tokenEE =
    let Just b = preview token "cRIhk3UyxiABoafo4h100kZcjGQQJ/UDEVjM4qv/Htcn2LNApJkhIc6hzDPvujgCmRV3CRY1Up4a"
        Just r = preview token "QVuRV4RxA2lO8B6y8vOIi03pZMSj8S8F/LsMxCyfA3OBtgmB1IFh51aMSeh4qjBid9nNmk3BOYr0"
    in (b,r)

tokenRV :: (Token, Token)
tokenRV =
    let Just b = preview token "AjMuHxnw5TIrO9C2BQStlXUv6luAWmg7pt1GhVjYctvD8w3eZE9eEjbyGsVjrJT8S11egXsOi7e4"
        Just r = preview token "E4VkzDDDm8till5xSYIeOO8GbnSYtBHiIIClwdd46+J9K/dH/l5YVBFXLHmHZno5YAVtIp84GLwH"
    in (b,r)

tokenRR :: (Token, Token)
tokenRR =
    let Just b = preview token "/D6TJwBSK18sB0cLyVWdt38Pca5keFb/sHeblGNScQI35qhUZwnMZh1Gz9RSIjFfxmBDdHeBWeLM"
        Just r = preview token "++1ZuShqJ0BQ7uesZGus2G+IGsETS7jn1ZhfjohBx1SzrJbviQ1MkemmGWtZOxbcbtJS+gANj+Es"
    in (b,r)

-- | This isn't even a token, just some made up words.
tokenDERP :: (Token, Token)
tokenDERP =
    let Just b = preview token "lemmeinlemmeinlemmeinlemmeinlemmeinlemmeinlemmeinlemmeinlemmeinlemmeinlemmein"
        Just r = preview token "pleasepleasepleasepleasepleasepleasepleasepleasepleasepleasepleasepleaseplease"
    in (b,r)
