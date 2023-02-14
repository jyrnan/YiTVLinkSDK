//
//  YMLNWBrowser.swift
//  DemoNetworkApp
//
//  Created by jyrnan on 2023/1/23.
//

import Network

var sharedBrowser: YMLNWBrowser?

// Update the UI when you receive new browser results.
protocol YMLNWBrowserDelegate: AnyObject {
    func refreshResults(results: Set<NWBrowser.Result>)
    func displayBrowseError(_ error: NWError)
}

class YMLNWBrowser {

    weak var delegate: YMLNWBrowserDelegate?
    var browser: NWBrowser?

    // Create a browsing object with a delegate.
    init(delegate: YMLNWBrowserDelegate) {
        self.delegate = delegate
        startBrowsing()
    }

    // Start browsing for services.
    func startBrowsing() {
        // Create parameters, and allow browsing over a peer-to-peer link.
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        // Browse for a custom "_tictactoe._tcp" service type.
        let browser = NWBrowser(for: .bonjour(type: "_demoNWapp._tcp", domain: nil), using: parameters)
        self.browser = browser
        browser.stateUpdateHandler = { newState in
            switch newState {
            case .failed(let error):
                // Restart the browser if it loses its connection.
                if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_DefunctConnection)) {
                    print("Browser failed with \(error), restarting")
                    browser.cancel()
                    self.startBrowsing()
                } else {
                    print("Browser failed with \(error), stopping")
                    self.delegate?.displayBrowseError(error)
                    browser.cancel()
                }
            case .ready:
                // Post initial results.
                self.delegate?.refreshResults(results: browser.browseResults)
            case .cancelled:
                sharedBrowser = nil
                self.delegate?.refreshResults(results: Set())
            default:
                break
            }
        }

        // When the list of discovered endpoints changes, refresh the delegate.
        browser.browseResultsChangedHandler = { results, changes in
            self.delegate?.refreshResults(results: results)
        }

        // Start browsing and ask for updates on the main queue.
        browser.start(queue: .main)
    }
}

