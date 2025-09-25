// performanceMonitor.js
export class ComponentPerformanceMonitor {
    static startTiming(componentName, operation) {
        const key = `${componentName}_${operation}`;
        performance.mark(`${key}_start`);
        return key;
    }
    
    static endTiming(key) {
        performance.mark(`${key}_end`);
        performance.measure(key, `${key}_start`, `${key}_end`);
        
        const measure = performance.getEntriesByName(key)[0];
        
        // Log slow operations (>1000ms)
        if (measure.duration > 1000) {
            console.warn(`⚠️ Slow operation detected: ${key} took ${measure.duration}ms`);
        }
        
        // Send to analytics if needed
        this.reportPerformanceMetric(key, measure.duration);
    }
    
    static reportPerformanceMetric(operation, duration) {
        // 🚀 Replace console.log with your custom telemetry/analytics endpoint
        console.log(`📊 Performance: ${operation} - ${duration}ms`);
    }
}
