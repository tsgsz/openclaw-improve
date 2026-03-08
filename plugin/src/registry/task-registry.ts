import { Task } from '../types';

export class TaskRegistry {
  private tasks: Map<string, Task>;
  private maxSize: number;

  constructor(maxSize: number = 1000) {
    this.tasks = new Map();
    this.maxSize = maxSize;
  }

  set(taskId: string, task: Task): void {
    // LRU eviction: remove oldest completed task if at capacity
    if (this.tasks.size >= this.maxSize) {
      for (const [id, t] of this.tasks.entries()) {
        if (t.status === "completed" || t.status === "failed" || t.status === "timeout") {
          this.tasks.delete(id);
          break;
        }
      }
    }
    this.tasks.set(taskId, task);
  }

  get(taskId: string): Task | undefined {
    return this.tasks.get(taskId);
  }

  getAll(): Task[] {
    return Array.from(this.tasks.values());
  }

  delete(taskId: string): boolean {
    return this.tasks.delete(taskId);
  }

  get size(): number {
    return this.tasks.size;
  }
}
