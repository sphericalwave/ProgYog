//
//  SessionInfoDetailView.swift
//  ProgYog
//

import SwiftUI

struct SessionInfoDetailView: View {
    @ObservedObject var session: Session
    @EnvironmentObject private var services: AppServices

    @FetchRequest private var setLogs: FetchedResults<SetLog>

    init(session: Session) {
        self.session = session
        _setLogs = FetchRequest<SetLog>(
            sortDescriptors: [NSSortDescriptor(key: "loggedAt", ascending: true)],
            predicate: NSPredicate(format: "session == %@", session)
        )
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Name", value: WorkoutLabel.display(for: session))
                DatePicker("Started", selection: startBinding)
                Toggle("Completed", isOn: completedBinding)
                if session.endedAt != nil {
                    DatePicker("Ended",
                               selection: endBinding,
                               in: session.startedAt...)
                }
                LabeledContent("Sets", value: "\(setLogs.count)")
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Session")
    }

    private var startBinding: Binding<Date> {
        Binding(
            get: { session.startedAt },
            set: { new in
                SessionEditor.shiftStart(session, to: new)
                services.coreData.save()
            }
        )
    }

    private var endBinding: Binding<Date> {
        Binding(
            get: { session.endedAt ?? session.startedAt },
            set: { new in
                SessionEditor.setEnd(session, to: new)
                services.coreData.save()
            }
        )
    }

    private var completedBinding: Binding<Bool> {
        Binding(
            get: { session.endedAt != nil },
            set: { on in
                SessionEditor.setCompleted(session, on)
                services.coreData.save()
                WorkoutCalendarBridge.syncSegments(session)
            }
        )
    }
}
