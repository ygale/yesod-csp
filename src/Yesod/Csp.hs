{-# LANGUAGE OverloadedStrings #-}

module Yesod.Csp (
  cspPolicy
  , getCspPolicy
  , DirectiveList
  , Directive(..)
  , SourceList
  , Source(..)
  ) where

import           Data.List.NonEmpty
import           Data.Text          hiding (filter, null)
import qualified Data.Text          as T
import           Network.URI
import           Yesod.Core

cspPolicy :: (MonadHandler m) => DirectiveList -> m ()
cspPolicy = addHeader "Content-Security-Policy" . directiveListToHeader

getCspPolicy :: DirectiveList -> Text
getCspPolicy = directiveListToHeader

withSpaces :: NonEmpty Text -> Text
withSpaces = T.intercalate " " . toList

w :: Text -> SourceList -> Text
w = wrap

wrap :: Text -> SourceList -> Text
wrap k x = mconcat [k, " ", textSourceList x]

data Source = Wildcard
              | None
              | Self
              | DataScheme
              | DomainName URI
              | Https
              | UnsafeInline
              | UnsafeEval deriving (Eq)

type SourceList = NonEmpty Source

textSource :: Source -> Text
textSource Wildcard = "*"
textSource None = "'none'"
textSource Self = "'self'"
textSource DataScheme = "data:"
textSource (DomainName x) = (pack . show) x
textSource Https = "https:"
textSource UnsafeInline = "'unsafe-inline'"
textSource UnsafeEval = "'unsafe-eval'"

textSourceList :: SourceList -> Text
textSourceList = withSpaces . filtered
  where filtered = fmap textSource . filterOut

-- * and none should be alone if present
filterOut :: SourceList -> SourceList
filterOut x | Wildcard `elem` x = Wildcard :| []
filterOut x | None `elem` x = None :| []
            | otherwise = x

data Directive = DefaultSrc SourceList
                 | ScriptSrc SourceList
                 | StyleSrc SourceList
                 | ImgSrc SourceList
                 | ConnectSrc SourceList
                 | FontSrc SourceList
                 | ObjectSrc SourceList
                 | MediaSrc SourceList
                 | FrameSrc SourceList
                 | Sandbox (NonEmpty SandboxOptions)
                 | ReportUri Text

type DirectiveList = [Directive]
data SandboxOptions = AllowForms
                      | AllowScripts
                      | AllowSameOrigin
                      | AllowTopNavigation

directiveListToHeader :: DirectiveList -> Text
directiveListToHeader = T.intercalate "; " . fmap textDirective

textDirective :: Directive -> Text
textDirective (DefaultSrc x) = w "default-src" x
textDirective (ScriptSrc x) =  w "script-src" x
textDirective (StyleSrc x) =  w "style-src" x
textDirective (ImgSrc x) =  w "img-src" x
textDirective (ConnectSrc x) =  w "connect-src" x
textDirective (FontSrc x) =  w "font-src" x
textDirective (ObjectSrc x) =  w "object-src" x
textDirective (MediaSrc x) =  w "media-src" x
textDirective (FrameSrc x) =  w "frame-src" x
textDirective (ReportUri t) = mconcat ["report-uri ", t]
textDirective (Sandbox s) = mconcat ["sandbox", withSpaces . fmap textSandbox $ s]
  where textSandbox AllowForms = "allow-forms"
        textSandbox AllowScripts = "allow-scripts"
        textSandbox AllowSameOrigin = "allow-same-origin"
        textSandbox AllowTopNavigation = "allow-top-navigation"
