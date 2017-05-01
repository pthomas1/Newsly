//
//  NSObject+Synchronized.swift
//  Newsly
//
//  Created by Peter Thomas on 4/30/17.
//  Copyright © 2017 Peter Thomas. All rights reserved.
//

import UIKit

extension NSObject {

    func synchronized( block: () -> Void ) {
        objc_sync_enter(self)
        block()
        objc_sync_exit(self)
    }
}
