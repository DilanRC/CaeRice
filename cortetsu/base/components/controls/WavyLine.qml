import QtQuick
import QtQuick.Shapes

// First-party wavy-line control.
// It keeps the caller-facing contract while drawing the wave with ShapePath.
Shape {
    id: root

    enum PathType {
        Linear,
        Arc
    }

    property int lineWidth: 2
    property real amplitudeMultiplier: 0
    property int frequency: 6
    property real startX: 0
    property real fullLength: width
    property color color: "white"
    property real waveProgress: 0
    property int pathType: WavyLine.Linear
    property real startAngle: 0
    property real fullAngle: 360
    property real radius: Math.min(width, height) / 2
    property real value: 1

    preferredRendererType: Shape.CurveRenderer
    asynchronous: true

    ShapePath {
        strokeColor: root.color
        strokeWidth: root.lineWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap

        PathSvg {
            path: {
                const amplitude = root.lineWidth * root.amplitudeMultiplier;
                const count = Math.max(1, root.frequency);
                const points = [];
                if (root.pathType === WavyLine.Arc) {
                    const sweep = root.fullAngle * Math.max(0, Math.min(1, root.value));
                    const centerX = root.width / 2;
                    const centerY = root.height / 2;
                    const steps = Math.max(12, count * 12);
                    for (let i = 0; i <= steps; i++) {
                        const fraction = i / steps;
                        const angle = (root.startAngle + sweep * fraction) * Math.PI / 180;
                        const radius = root.radius + amplitude * Math.sin((fraction + root.waveProgress) * count * 2 * Math.PI);
                        points.push(`${centerX + radius * Math.cos(angle)},${centerY + radius * Math.sin(angle)}`);
                    }
                } else {
                    const start = root.startX;
                    const length = Math.max(0, root.fullLength);
                    const steps = Math.max(16, count * 12);
                    for (let i = 0; i <= steps; i++) {
                        const fraction = i / steps;
                        const x = start + length * fraction;
                        const y = root.height / 2 + amplitude * Math.sin((fraction + root.waveProgress) * count * 2 * Math.PI);
                        points.push(`${x},${y}`);
                    }
                }
                return points.length > 0 ? `M ${points.join(" L ")}` : "";
            }
        }
    }
}
