import Foundation

final class AnnotationProjectStore {
    private let projectsKey = "annotationProjects"

    func saveProject(_ project: AnnotationProject) {
        var projects = getAllProjects()
        projects.removeAll { $0.id == project.id }
        projects.append(project)
        saveProjects(projects)
    }

    func getProject(forRecording recordingId: UUID) -> AnnotationProject? {
        getAllProjects().first { $0.recordingId == recordingId }
    }

    func deleteProject(id: UUID) {
        var projects = getAllProjects()
        projects.removeAll { $0.id == id }
        saveProjects(projects)
    }

    func getAllProjects() -> [AnnotationProject] {
        guard let data = UserDefaults.standard.data(forKey: projectsKey),
              let projects = try? JSONDecoder().decode([AnnotationProject].self, from: data) else {
            return []
        }
        return projects
    }

    private func saveProjects(_ projects: [AnnotationProject]) {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: projectsKey)
        }
    }
}
