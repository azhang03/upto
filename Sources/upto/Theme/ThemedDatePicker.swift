import AppKit
import SwiftUI

// A date and time field without the system bezel, so it sits cleanly
// inside the field chrome. Editing mechanics stay native. The picker
// reports when it takes or gives up editing so the caller can style
// the row and move focus.
struct ThemedDatePicker: NSViewRepresentable {
    @Binding var date: Date
    var elements: NSDatePicker.ElementFlags = [.yearMonthDay, .hourMinute]
    var onEditingChanged: ((Bool) -> Void)? = nil

    func makeNSView(context: Context) -> ReportingDatePicker {
        let picker = ReportingDatePicker()
        picker.datePickerStyle = .textFieldAndStepper
        picker.datePickerElements = elements
        picker.isBezeled = false
        picker.isBordered = false
        picker.drawsBackground = false
        picker.font = NSFont.systemFont(ofSize: 13)
        picker.target = context.coordinator
        picker.action = #selector(Coordinator.dateChanged(_:))
        return picker
    }

    func updateNSView(_ picker: ReportingDatePicker, context: Context) {
        context.coordinator.parent = self
        picker.onEditingChanged = onEditingChanged
        if picker.dateValue != date {
            picker.dateValue = date
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: ThemedDatePicker

        init(_ parent: ThemedDatePicker) {
            self.parent = parent
        }

        @objc func dateChanged(_ sender: NSDatePicker) {
            parent.date = sender.dateValue
        }
    }

    final class ReportingDatePicker: NSDatePicker {
        var onEditingChanged: ((Bool) -> Void)?

        override func becomeFirstResponder() -> Bool {
            let accepted = super.becomeFirstResponder()
            if accepted {
                onEditingChanged?(true)
            }
            return accepted
        }

        override func resignFirstResponder() -> Bool {
            let accepted = super.resignFirstResponder()
            if accepted {
                onEditingChanged?(false)
            }
            return accepted
        }
    }
}
